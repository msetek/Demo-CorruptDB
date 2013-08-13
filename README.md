Install:

* nginx
* memcached
* [siege](http://www.joedog.org/index/siege-home)

Running:

* Start nginx with the supplied config (tweaking port, location of fastcgi_params, etc. as necessary).
* Start memcached on localhost, port 11211 like this:
    memcached -d
* Start the fcgi backends like this (adjust -n 4 to the number of CPU cores available / 2):
    ./script/demo_corruptdb_fastcgi.pl -l 127.0.0.1:8999 -p app.pid -n 4 -e
  
Run siege against http:://localhost:3000/ like this (adjust -c 4 to the number of CPU cores available):

    siege -c 4 http:://localhost:3000/

or

    siege -c 4 http:://localhost:3000/memcached/

Comment in the implementation of Berkeley DB to test in lib/Demo/CorruptDB/Controller/Root.pm:

    BEGIN {
        # @AnyDBM_File::ISA = qw(DB_File) # Breaks
        # @AnyDBM_File::ISA = qw(GDBM_File) # Breaks
        @AnyDBM_File::ISA = qw(NDBM_File) # Breaks, but only sometimes?
        # @AnyDBM_File::ISA = qw(ODBM_File) # Breaks
    }   

And watch how it breaks under load with siege. Note that the implementation uses
ANY_DBM_File and will fall back to a default if the requested implementation
isn't found (see 'perldoc AnyDBM_File' for details).
