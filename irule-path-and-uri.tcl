# If the query parameter companyabc-erp exists, redirect the request based on query parameter value (1 to SAP Customer App, else to PS Customer App)
# If the cookie COOKIEABC exists, redirect the request based on cookie value (1 to SAP Customer App, else to PS Customer App)
# Otherwise redirect the request to PS Customer App
#

proc cretaeGuid {
    append s [clock seconds] [IP::local_addr] [IP::client_addr] [expr { int(100000000 * rand()) }] [clock clicks]
    set s [md5 $s]
    binary scan $s c* s
    lset s 8 [expr {([lindex $s 8] & 0x7F) | 0x40}]
    lset s 6 [expr {([lindex $s 6] & 0x0F) | 0x40}]
    set s [binary format c* $s]
    binary scan $s H* s
    append u [substr $s 0 8] "-" [substr $s 8 4] "-" [substr $s 12 4] "-" [substr $s 16 4] "-" [substr $s 20 12]
    unset s
    return $u
}
when CLIENT_ACCEPTED {
    set uid [call  cretaeGuid ]
}
when HTTP_REQUEST {
  set my_http_req "client_addr:[IP::client_addr] X-Forwarded-For:[HTTP::header "X-Forwarded-For"] method:[HTTP::method] host:[HTTP::host] port:[TCP::local_port] uri:[HTTP::uri]"
  log local0. "uid: $uid $my_http_req  companyabc-erp:[URI::query [HTTP::uri] companyabc-erp ]"
  set pm "none"
  if { [URI::query [HTTP::uri]]  contains "pm" } {
    set pm [URI::query [HTTP::uri] pm ]
  }
  switch $pm {
    "w1" {   set pm1 "10.131.223.145"    }
    "w2" {   set pm1 "10.131.223.146"    }
    default { set pm1 "none"    }
  }
  log local0. "uid: $uid $my_http_req  companyabc-erp:[URI::query [HTTP::uri] companyabc-erp ]  pm1:$pm1"
  if { [HTTP::uri] contains "/myaccount" }{
    set ETR_POOL "PS"
    if { [URI::query [HTTP::uri]]  contains "companyabc-erp" } {
      if { [URI::query [HTTP::uri] companyabc-erp]  eq "1"  } {
        set ETR_POOL "SAP"
      }
    } else {
      if { [HTTP::cookie exists COOKIEABC]   } {
        if { [HTTP::cookie value COOKIEABC] eq "1" } {
          set ETR_POOL "SAP"
        }
      }
    }
  } else {
    set ETR_POOL "STATIC"
  }
  switch $ETR_POOL {
    "SAP" {
      if { $pm1 eq "none" }{
        pool wwwdev.companyabc.com_8081_pool
      } else {
        pool wwwdev.companyabc.com_8081_pool member $pm1 8081
      }
      persist cookie insert wwwdev-myaccount 7200
    }
    "PS" {
      if { $pm1 eq "none" }{
        pool wwwdev.companyabc.com_8080_pool
      } else {
        pool wwwdev.companyabc.com_8080_pool member $pm1 8080
      }
      persist cookie insert wwwdev-myaccount 7200
    }
    default {
      if { $pm1 eq "none" }{
        pool wwwdev.companyabc.com_7080_pool
      } else {
        pool wwwdev.companyabc.com_7080_pool member $pm1 7080
      }
      persist none
    }
  }
}
when HTTP_RESPONSE {
  log local0. "uid: $uid status:[HTTP::status] Client_IP_Src: [IP::client_addr]:[TCP::client_port] pool_member_IP:[LB::server]"
}
