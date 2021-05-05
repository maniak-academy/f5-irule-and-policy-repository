when HTTP_REQUEST {
  if { [HTTP::uri] contains "/myaccount" }{
    set ETR_POOL "PS"
    if { [URI::query [HTTP::uri]]  contains "ABC" } {
      if { [URI::query [HTTP::uri] ABC]  eq "1"  } {
        set ETR_POOL "SAP"
      }
    } else {
      if { [HTTP::cookie exists ABC]   } {
        if { [HTTP::cookie value ABC] eq "1" } {
          set ETR_POOL "SAP"
        }
      }
    }
  } else {
    set ETR_POOL "STATIC"
  }
  switch $ETR_POOL {
    "SAP" {
      pool sap_pool
      persist cookie insert cookie 7200
      log local0. "sap_pool"
    }
    "PS" {
      pool ps_pool
      persist cookie insert cookie 7200
      log local0. "ps_pool"
    }
    default {
      pool static_pool
      persist none
      log local0. "static_pool"
    }
  }
}
