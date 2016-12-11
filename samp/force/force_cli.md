==

https://force-cli.heroku.com/

  It's a Go program should work.
  I downloaded the Ubuntu 64 I believe.



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
 00380318   | 005A0000007akYNIAY | Waiting for Customer 
 00378173   | 005A0000007akYNIAY | Waiting for Customer 
 00387772   | 005A0000007akYNIAY | In Progress          
 00387496   | 005A0000007akYNIAY | Waiting for Customer 
 00379541   | 005A0000007akYNIAY | Closed               
 00386557   | 005A0000007akYNIAY | Closed               
 00387657   | 005A0000007akYNIAY | Closed               
 00386379   | 005A0000007akYNIAY | Closed               
 00385365   | 005A0000007akYNIAY | Closed               
 00383320   | 005A0000007akYNIAY | Closed               
 00383418   | 005A0000007akYNIAY | Closed               
 (12 records)

jeff@ubuntu:~$ force query "Select User.Id,User.Name from User WHere User.Name = 'Roy Rim'" --format:json
[{"Id":"005A0000007GRWaIAO","Name":"Roy Rim","attributes":{"type":"User","url":"/services/data/v37.0/sobjects/User/005A0000007GRWaIAO"}}]

