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


Contributors
------------
I'd like to thank the following people for making substantial contributions to this project in one way or another:

Vijay Atwater-Van Ness [@XAMPP](https://github.com/XAMPP/)  
Corey Matyas [@coreymatyas](https://github.com/coreymatyas/)  
Mike Korcha [@mkorcha](https://github.com/mkorcha/)  


License
-------
Code written specifically for this project is released under the BSD 3-Clause license. Vibe.D is released under the MIT public license. libcmark is released under a variety of free and non-restrictive licenses, which you are encouraged to review in detail. TinyRedis is released under the ISC license.