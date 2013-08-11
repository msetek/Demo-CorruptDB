use strict;
use warnings;

use Demo::CorruptDB;

my $app = Demo::CorruptDB->apply_default_middlewares(Demo::CorruptDB->psgi_app);
$app;

