# SmartRentEx

I moved into an apartment that has a SmartRent/Alloy box pre-installed, and so I wanted to know how it works. 

This is a hacky library to control all the SmartRent stuff in the apartment on my own terms.

If you have a SmartRent/Alloy account you can connect to all your devices using the follow code snippet to create a "Head of Household" agent:

`agent_pid = SmartRentEx.create_hoh_agent(email, password)`

This agent will enumerate all the devices in your SmartRent account and subscribe to events from them.