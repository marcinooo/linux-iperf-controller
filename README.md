
```
   __    _____    ___  
  / /    \_   \  / __\ 
 / /      / /\/ / /    
/ /___ /\/ /_  / /___  
\____/ \____/  \____/  

- it means Linux Iperf Controller
```


## What is it?


This is a "simple" script that will allow you to run multiple iperfs on multiple hosts. LIC was created during the student times and nowadays there are better solutions (like ansible). LIC can still be useful in environments without Internet access, where it is enough to connect a USB drive and copy the script to your host. In addition, the LIC source code contains many useful tricks in bash, so it's worth having it on the repo ;).


## How to use it?

First of all generate a configuration file, which contains iperf commands and host details:

```
$ ./lic.sh -g config.json
Configuration was saved in config.json
$
```

Above command creates file: 

```
$ cat config.json
{
    "data-transfers": {
        "ul-udp": {
            "client": {
                "cmd": "iperf -u -c 127.0.0.1 -b 100M -t 5s -i 1",
                "host": "hostA"
            },
            "server": {
                "cmd": "iperf -s -u -i 1",
                "host": "hostB"
            }
        }
    },
    "hosts": {
        "hostA": {
            "ip": "<ip>",
            "username": "<username>",
            "password": "<password>"
        },
        "hostB": {
            "ip": "<ip>",
            "username": "<username>",
            "password": "<password>"
        }
    }
}
```

Replace **\<ip\>** **\<username\>** **\<password\>** tags in above file with your host data (you can type here your *localhost* as well).
Of course you can also change the **cmd** parameter - that's why this tool was created :wink:. Type there iperf command which should be executed on remote host. For server iperf command skip **-p** option. Port will be allocated automatically. 
Parametr **host** indicates where given cmd should be executed.

Run shell if you already have generated configuration file:

```
$ ./lic.sh -c config.json
Welcome to the Linux Iperf Controller shell.

Checking libraries...
- jq... OK
- xterm... OK

Checking configuration... OK

Type help or ? to list commands.

(LIC)>
```

The LIC shell accepts several different commands to manage iperf. Possible commands are listed below.

- Start data transfer. It will open 2 addtional windows with server and client iperf.
    ```
    (LIC)> start ul-udp
    Starting "ul-udp" data transfer...
    (LIC)>
    ```
    
    Opend windows:

    ![alt Opend iperf windows](https://raw.githubusercontent.com/marcinooo/linux-iperf-controller/main/images/running-data-transfer.png)

- Stop data transfer:
    ```
    (LIC)> stop ul-udp
    Stoping "ul-udp" data transfer...
    (LIC)>
    ```

    Opend windows will be closed.

- Quit LIC:
    ```
    (LIC)> quit
    See you!
    $
    ```

- Check commands:
    ```
    (LIC)> ?
    Commands:
    start <data transfer name> - start given data transer; 
                                 if no data transfer name is given then all data transfers from the configuration file will be started
    stop  <data transfer name> - stop given data transer; 
                                 if no data transfer name is given then all data transfers from the configuration file will be stoped
    quit or q                  - quit linux iperf controller
    help or ?                  - show this help
    ```

## Can I develop it?

The entire tool is contained in one file. This is to make it easier to move the LIC tool between hosts. If you need new functionalities, add them in the lic.sh file. Remember to add new tests after making changes and run all tests.

![alt Tests results](https://raw.githubusercontent.com/marcinooo/linux-iperf-controller/main/images/tests.png)
