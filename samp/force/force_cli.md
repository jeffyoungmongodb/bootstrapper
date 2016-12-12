Force Cli
===============

https://force-cli.heroku.com/

  It's a Go program should work.
  I downloaded the Ubuntu 64 I believe.

https://github.com/heroku/force

Example Session
========
  
   
 ./force login -i=mongodb.my.salesforce.com
  --> Login and allow ...


jeff@ubuntu:~/Downloads$ ./force query "Select User.Id,User.Name from User WHere User.Name = 'Jeff Young'"
 Id                 | Name       
--------------------+------------
 005A0000007akYNIAY | Jeff Young 
 (1 records)
jeff@ubuntu:~/Downloads$ ./force query "Select Case.OwnerId,Case.Status,Case.CaseNumber from Case WHere Case.OwnerId = '005A0000007akYNIAY'"
 CaseNumber | OwnerId            | Status               
------------+--------------------+----------------------
 00378859   | 005A0000007akYNIAY | Waiting for Customer 
...
 (12 records)

jeff@ubuntu:~$ force query "Select User.Id,User.Name from User WHere User.Name = 'Roy Rim'" --format:json
[{"Id":"005A0000007GRWaIAO","Name":"Roy Rim","attributes":{"type":"User","url":"/services/data/v37.0/sobjects/User/005A0000007GRWaIAO"}}]

jeff@ubuntu:~$ force query "Select Id,CaseNumber from Case Where CreatedDate > 2016-12-09T23:01:01Z" --format:json
...

And you are off....
