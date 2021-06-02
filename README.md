# SmartRentEx

I moved into an apartment that has a SmartRent/Alloy box pre-installed, and so I wanted to know how it works. 

This is a hacky library to control all the SmartRent stuff in the apartment on my own terms.

**ONCE AGAIN THIS IS HACK, NOT SUPPORTED BY SMARTRENT AND TOTALLY A WEEKEND PROJECT. IT WILL PROBABLY BREAK**

## Architecture

### Physical Summary

SmartRent/Alloy installs a "hub" inside your unit which connects via 4G/WiFi/Ethernet to their servers. This hub is probably a Zipato made box called a "Zipabox" with a pair of antenna or a smaller Zipalite box. Either way they connect to SmartRent's servers and listen for events which are translated into Zipato API commands.

These commands direct the box to communicate with IoT devices via Zigbee usually.

There is no public API for SmartRent and the Zipato API is closed off inside the box itself. (There are some fun ways to get inside the box but that's outside the scope of this repo.)

There IS however a SmartRent API for their App and Website to send events to your box. That is what this repo interacts with.

### Their Stack (some of it i guess)

 * Elixir
 * Phoenix Web Framework
 * React
 * Phoenix Sockets API to send and receive attribute updates per device.
 * RESTful API to query a list of hubs and devices and user info. (Maybe more? I don't know.)

### How This Library Works

Here's a basic diagram of how this is put together.

```
              +---------------+                            
              | YOUR COOL APP |                            
              +---------------+                            
                      |                                    
                      | (call and cast)                    
                      |                                    
              +---------------+                            
              |     AGENT     |                            
              |   GenServer   |                            
              +---------------+                            
              |               |                            
 (Tesla HTTP) |               | (Phx Socket)               
              |               |                            
 +------------------+  +--------------------+              
 |SmartRent REST API|  |SmartRent Socket API|              
 +------------------+  +--------------------+              
                       |                                   
                       |                                   
                       |         +----------+              
                       |---------| Device X |              
                       |         |----------|              
                       |---------| Device Y |              
                       |         |----------|              
                       |---------| Device Z |              
                                 +----------+              
```

Basically, an Agent is a GenServer that holds the session credentials, the hub list, the device list, and persistent connections to devices you ask it to connect to.
It will auto-retry if connections are lost to devices. 

You interact with this agent by `call`ing and `cast`ing messages to it.

### Example Usage

#### Connecting

First lets connect to the API using our user credentials, which you'll have after signing up using the fancy marketing pamphlet they hand you during move-in.

```elixir
agent = SmartRentEx.create_hoh_agent("email@example.com", "hopefully-a-better-password-than-this", []) # <-- we'll get to this list next!!
```

We call this `create_hoh_agent/3` function because it helps setup some stuff you probably want to work out of the box, like automatically connecting to all the devices registered to the first hub in the system so you don't need to do it all by hand. I call this the "Head of Household" agent because it has knowledge of all devices connected to the hub. (Maybe you don't want this, in that case call `create_agent/2` instead and all it will do is auth you.)

The return value of this snippet is a PID to the newly created GenServer. It'll log out some useful information but it's almost always ready to yse within 1 second of booting it up.

#### Processing events

Say your door unlocks or your thermostat changes, you may want to do something with this information. When you first call `create_hoh_agent/3` the 3rd argument is a list of modules you can pass in to be forwarded events as the agent receives them.

Define a module like this

```elixir
defmodule MyCoolApp.EventProcessor do
  @behaviour SmartRentEx.CallbackModule

  def smartrent_event(message, src_agent_pid) do
    # Do something with message.payload 
  end
end
```

Then when you call `create_hoh_agent/3` just pass it in the list as the 3rd argument.

```elixir
agent = SmartRentEx.create_hoh_agent(email, password, [MyCoolApp.EventProcessor])
```

Now whenever the agent gets a message from the socket API, the `smartrent_event/2` function will be called with the socket message and the agent PID as the two arguments! Have fun!

#### Changing Attributes

Let's say you have an agent, and you want to change the temperature on your living room thermostat. Assuming you already have a head of household agent...

First assign a hub as the agent's current active hub. You probably only have one, so call this out to the agent and it will just assign the first hub in the list on your account:

```elixir
:ok = GenServer.call(agent, :set_active_hub)
```

Now let's fetch a list of devices attached to that hub:

```elixir
device_list = GenServer.call(agent, :get_devices)
thermostat = List.list(device_list)
```

(Assuming the thermostat is the list element in the returned device list for simplicity!)

Now let's set the HEAT temperature on this thermostat to 65 degrees:

```elixir
alias SmartRentEx.Constants.CommonAttributes

GenServer.cast(agent, {:set_device_attribute, thermostat, CommonAttributes.thermostat_set_temp_heat, "65"})
```

That's it! The `CommonAttributes` module just contains some useful attribute names that are common across all the devices I've seen.
That list will probably grow over time.