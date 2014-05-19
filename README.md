2Do-iOS-App
===========

To-Do application that backs up your lists and can be access from multiple devices

Simply add your task using the + button and fill out the relevant fields.

To mark a task as complete, simply press the tick button on the right of the task on the ToDo/Completed screen.

Once a task has been added, you can synchronise them with the server manually by simply pulling the table down on either the ToDo or Completed screen.

The synchronisatoion will fire automatically every 60 seconds, even if the user manually syncs with the web server.


Future Improvements
===================

- integrate Apple Push Notifications so the server can notify users of upcoming tasks.
- emailing. e.g. daily digest of the tasks for that day
- user tagging. e.g. include another user into a task
- group tasks - ability to join/create/leave/invite groups of people that tasks will be shared amongst
- filtering - ability to filter tasks
- search functionality to search through current tasks
- social network SSO support - so users can log in using their social networking account (Facebook, Twitter, Linked-In, etc..)

Challenges Faced
================

The hardest part of this application was ensuring all the tasks would sync correctly with each other. I had to devise a way to be able to pull down the tasks from the server, add any that hadnt been added before (but being avoid re-adding tasks that have been deleted locally), and upload new tasks to the server that have been created on the divice.

I wanted the application to work offline. Which would mean persisting the data to the divice. But I also wanted users to be able to use the app on other devices and have the data automagically appear accross them all. This meant that the synchronisation of the tasks would also have to take into consideration any updates to a tasks that may have been made on another device. Whats more, this update might happen while any given device is offline. Which brings me to my next point that tasks could also be created or deleted offline too.

So I have stored the updated date within the managed object of each task. When the users divice is online and able to sync, it will check if each task is newer than the one on the server. If so it updates the servers task with the local task data.
It also does NOT add a task ID when the task is created locally. This means that when the sync happens, it can check through each of the local tasks and any that dont have a task ID are at this point created on the server. The web service will respond with a task id, which is updated in the managed object for the task and saved.
When a task is deleted from the device, it simply sets a boolen flag within the tasks managed object. Once the sync occurs successfully and deletes it from the server, the web service responds with if it was successful or not, if so then the task is removed from the divice.

Of course to allow the user to be able to use the application offline, once a user has registered or logged into the app successfully, an entry is made recording the users details. On furture login attempts, the application will look to see if the user exists locally before making the call to the web service to authenticate them. This means that any user that has previosly logged into the application using that device in the past, will continue to be able to do so once the divice is offline.

Web Service Info
================

I wrote the web service myself in Java using JAX_WS.
It is hosted on one of my own dedicated servers running Linux.
I created a sub domain from one of my URLs to point to the server.
The web service is deployed within a Tomcat container, so I also had to set up the apache configuration to allow a proxy pass and reverse through to/from this.

Automatic building and deployment has been scipted using Ant.

I am using a MySQL database and jdbc to connect to it from the web application.
