# Intro

The vpn list on [expressvpn.com/setup#manual](https://www.expressvpn.com/setup#manual) can be copied and transformed into a transmission-ovpn readable format, to create it from scratch with the kost recent servers. With the regex steps below (search & replace), this can be easily transformed

### remove heades

`Americas\n`  
`Europe\n`  
`Asia Pacific\n`  
`Middle East & Africa\n`  

### to lowercase

`(\w)`  
`\L$1`  

### whitespaces to underscore

`\s`  
`_`  

### append protocol type

`(.*)`  
`$1_udp`  

### prepend my_expressvpn_

`(.*)`  
`my_expressvpn_$1`  
