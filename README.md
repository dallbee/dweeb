Dweeb
=====

An implementation of my personal website written in D, to mirror the C implementation at the [allbee.org repository](https://github.com/dallbee/allbee.org).

The intent of the project is to provide an example of using the Vibe.D framework, as well as server as a comparison to the Lwan framework.


Building
--------
The following are required before building

 - [Vibe.D](http://vibed.org/), at least version 2.8
 - [cmark](https://github.com/jgm/cmark)

You will of course also need the related dependencies.

```
git clone --recursive https://github.com/dallbee/dweeb.git
cd dweeb
git submodule foreach "git checkout master"
dub build
```

You can then run the generated server file. If you want to build the frontend dependencies as well, you'll need to do some additional work

```
## TO BE COMPLETED
```

Kernel Tuning
-------------
While everything should run fine on a default linux install, there's some tuning that can be done to ensure the stability and response time of the program.

- `fs.inotify.max_user_watches` Any process that listens for directory modifications will use one "watch" per file/directory. Dweeb has several thousand files associated with it, and so simply having an auto reload script running in tandem with dweeb's content watcher is likely enough to go over the default limit of 8192. I usually increase this by at least a factor of two.
- `fs.file-max` One item of this resource is used per static file served, per concurrent user. The default is usually good enough but this may need to be increased for a high-load server.
- Add noatime to the mount option for your filesystem to remove access time from file statistics.


Contributors
------------
I'd like to thank the following people for making substantial contributions to this project in one way or another:

Vijay Atwater-Van Ness [@XAMPP](https://github.com/XAMPP/)  
Corey Matyas [@coreymatyas](https://github.com/coreymatyas/)  
Mike Korcha [@mkorcha](https://github.com/mkorcha/)  


License
-------
Code written specifically for this project is released under the BSD 3-Clause license. Vibe.D is released under the MIT public license. libcmark is released under a variety of free and non-restrictive licenses, which you are encouraged to review in detail.