# Demo of how using a Berkeley DB concurrently without locking can break under load

## Install

* nginx
* memcached
* [siege](http://www.joedog.org/index/siege-home)
* libmemcached

## Setup

* Start nginx with the supplied config (tweaking port, location of fastcgi_params, etc. as necessary).
* Start memcached on localhost, port 11211 like this:

    memcached -d

* Start the fcgi backends like this (adjust -n 4 to the number of CPU cores available / 2):

    ./script/demo_corruptdb_fastcgi.pl -l 127.0.0.1:8999 -n 4 -e
  
## Running

Run siege against http:://localhost:8080/ like this (adjust -c 4 to the number of CPU cores available):

    siege -c 4 http:://localhost:8080/

or

    siege -c 4 http:://localhost:8080/memcached/

Select the implementation of Berkeley DB to test in
lib/Demo/CorruptDB/Controller/Root.pm by adding/removing comments:

    BEGIN {
        # @AnyDBM_File::ISA = qw(DB_File) # Breaks
        # @AnyDBM_File::ISA = qw(GDBM_File) # Breaks
        @AnyDBM_File::ISA = qw(NDBM_File) # Breaks, but only sometimes?
        # @AnyDBM_File::ISA = qw(ODBM_File) # Breaks
    } 
    
And watch how it *breaks* under load with siege. It might be
necessary to remove corrupt DB's between runs (with 'rm
/tmp/corruptdb*').

The NDBM implementation breaks more easily when siege is run
without the -c option.

The memcached version was added for comparison. It doesn't break :)


