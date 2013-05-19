bind pub - "COM:" relay_message
bind pub - "COMM:" relay_message
bind pub - "COM" relay_message
bind pub - "COMM" relay_message

array set shiplist {
	elara Elara
	quirinus Quirinus
	arcadia Arcadia
}
array set taskforces {}
array set fleetassignment {}

#;;; Where the logs will be saved.
set logger(dir) "logs/"

#;;; Strip codes?
#;;; 0 = save codes\colors
#;;; 1 = no save codes\colors
set logger(strip) "1"

#;;; Save by Day, Week, Month or Disable?
set logger(time) "Month"

proc relay_message {nick uhost hand chan rest} {
	set target [string tolower [lindex [split $rest] 0]]
	set chan [string tolower $chan]

	global shiplist
	global taskforces
	global fleetassignment
	
	
	if {[string tolower $chan] != "#reflections_fleethq" && [string tolower $chan] != "#reflections_sensorgrid"} {
	set originship $shiplist([string tolower [string range $chan 13 [string length $chan]]])
	#set targetship [string range $target 0 [expr [string length $target] - 2]]
	set targetship [string trimright $target :]
	putlog "$nick sent COM MESSAGE TO $targetship of $rest"
	if {[string tolower $targetship] eq "all"} {
		set chanlist [lindex [channels]]
		foreach ch $chanlist {
			if {[string tolower $ch] != [string tolower $chan]} {
				putquick "PRIVMSG $ch : <$originship - $nick> @COM: $rest"
			}
		}
	} elseif {[validchan #Reflections_$targetship]} {
		putquick "PRIVMSG #Reflections_$targetship : <$originship - $nick> @COM: $rest"
		putquick "PRIVMSG #Reflections_SensorGrid : <$originship - $nick> COM: $rest"
	} else {
		set foundvalid 0
		foreach name [array names fleetassignment] {
			if {$fleetassignment($name) eq $targetship} {
				set foundvalid 1
				putquick "PRIVMSG #Reflections_$name : <$originship - $nick> @COM: $rest"
			}
		}
		if {$foundvalid eq 0} {
			putquick "PRIVMSG #Reflections_Command : <$originship - $nick> @COM: $rest"
		}
		putquick "PRIVMSG #Reflections_SensorGrid : <$originship - $nick> COM: $rest"
	}
	}
	return 1
}


bind pub - "ACTION:" relay_action
bind pub - "A:" relay_action

proc relay_action {nick uhost hand chan rest} {
	global shiplist
	set chanlist [channels]
	set originship $shiplist([string tolower [string range $chan 13 [string length $chan]]])

	if {[string tolower $chan] eq "#reflections_command"} {
		foreach ch $chanlist {
			if {[string tolower $ch] != "#reflections_fleethq"} {
				putquick "PRIVMSG $ch : <$nick> ACTION: $rest"
			}
		}
		putlog "$nick sent Mass Global Scene to all channels"
  if {[isop $nick $chan] == "1"} {
    set who "$originship - Host $nick says:"
  } elseif {[ishalfop $nick $chan] == "1"} {
    set who "$originship - Host $nick says:"
  } else {
    set who "$originship - $nick says:"
  }
  logger:save $who "ACTION: $rest"
	} else {
		putquick "PRIVMSG #Reflections_SensorGrid : <$originship - $nick> ACTION: $rest"
	}


	return 1
}

bind pub - "INFO:" relay_info
bind pub - "I:" relay_info

proc relay_info {nick uhost hand chan rest} {
	global shiplist
	set chanlist [channels]
	set originship $shiplist([string tolower [string range $chan 13 [string length $chan]]])
	if {[string tolower $chan] eq "#reflections_command"} {
		foreach ch $chanlist {
			if {[string tolower $ch] != "#reflections_fleethq"} {
				putquick "PRIVMSG $ch : <$nick> INFO: $rest"
			}
		}
		putlog "$nick sent Mass Info to all channels"
  if {[isop $nick $chan] == "1"} {
    set who "$originship - Host $nick says:"
  } elseif {[ishalfop $nick $chan] == "1"} {
    set who "$originship - Host $nick says:"
  } else {
    set who "$originship - $nick says:"
  }
  logger:save $who "INFO: $rest"
	} else {
		putquick "PRIVMSG #Reflections_SensorGrid : <$originship - $nick> INFO: $rest"
	}


	return 1
}

bind pub - "SCENE:" relay_scene
bind pub - "S:" relay_scene
proc relay_scene {nick uhost hand chan rest} {
	global shiplist
	set chanlist [channels]
	set originship $shiplist([string tolower [string range $chan 13 [string length $chan]]])
	if {[string tolower $chan] eq "#reflections_command"} {
		foreach ch $chanlist {
			if {[string tolower $ch] != "#reflections_fleethq"} {
				putquick "PRIVMSG $ch : <$nick> SCENE: $rest"
			}
		}
		putlog "$nick sent Mass Scene to all channels"
  if {[isop $nick $chan] == "1"} {
    set who "$originship - Host $nick says:"
  } elseif {[ishalfop $nick $chan] == "1"} {
    set who "$originship - Host $nick says:"
  } else {
    set who "$originship - $nick says:"
  }
  logger:save $who "SCENE: $rest"
	} else {
		putquick "PRIVMSG #Reflections_SensorGrid : <$originship - $nick> SCENE: $rest"
	}

	return 1
}


bind pub - "GLOBAL:" relay_global
bind pub - "G:" relay_global
bind pub - "GA:" relay_global
proc relay_global {nick uhost hand chan rest} {
	global shiplist
	set chanlist [channels]
	if {[string tolower $chan] eq "#reflections_command"} {
		foreach ch $chanlist {
			putquick "PRIVMSG $ch : GLOBAL ACTION: $rest"
		}
		putlog "$nick sent Mass Global Action to all channels"
	}

	set originship $shiplist([string tolower [string range $chan 13 [string length $chan]]])
  if {[isop $nick $chan] == "1"} {
    set who "$originship - Host $nick says:"
  } elseif {[ishalfop $nick $chan] == "1"} {
    set who "$originship - Host $nick says:"
  } else {
    set who "$originship - $nick says:"
  }
  logger:save $who "GLOBAL ACTION: $rest"
	return 1
}

bind pub - "GI:" relay_global_info
proc relay_global_info {nick uhost hand chan rest} {
	global shiplist
	set chanlist [channels]
	if {[string tolower $chan] eq "#reflections_command"} {
		foreach ch $chanlist {
			putquick "PRIVMSG $ch : GLOBAL INFO: $rest"
		}
		putlog "$nick sent Mass Global Info to all channels"
	}

	set originship $shiplist([string tolower [string range $chan 13 [string length $chan]]])
  if {[isop $nick $chan] == "1"} {
    set who "$originship - Host $nick says:"
  } elseif {[ishalfop $nick $chan] == "1"} {
    set who "$originship - Host $nick says:"
  } else {
    set who "$originship - $nick says:"
  }
  logger:save $who "GLOBAL INFO: $rest"
	return 1
}

bind pub - "GS:" relay_global_scene
proc relay_global_scene {nick uhost hand chan rest} {
	global shiplist
	set chanlist [channels]
	if {[string tolower $chan] eq "#reflections_command"} {
		foreach ch $chanlist {
			putquick "PRIVMSG $ch : GLOBAL SCENE: $rest"
		}
		putlog "$nick sent Mass Global Scene to all channels"
	}

	set originship $shiplist([string tolower [string range $chan 13 [string length $chan]]])
  if {[isop $nick $chan] == "1"} {
    set who "$originship - Host $nick says:"
  } elseif {[ishalfop $nick $chan] == "1"} {
    set who "$originship - Host $nick says:"
  } else {
    set who "$originship - $nick says:"
  }
  logger:save $who "GLOBAL SCENE: $rest"

	return 1
}

bind need - "% op" needop
proc needop {chan type} {
	global botnick
	putlog "I ($botnick) need op in $chan"
	putquick "MODE $chan +o $botnick"
	return 1
}

bind msg m "ship" msg_ship
proc msg_ship {nick host handle rest} {
	global shiplist
	global fleetassignment
	global taskforces
	set cmd [string tolower [lindex [split $rest] 0]]
	set shipname [lindex [split $rest] 1]
	if {$cmd eq "add"} {
		if {![validchan #Reflections_$shipname]} {
			channel add #Reflections_$shipname
			set shiplist([string tolower $shipname]) $shipname
			puthelp "PRIVMSG $nick : Added $shipname"
		}
	}
	if {$cmd eq "del"} {
		unset shiplist([string tolower $shipname])
		channel remove #Reflections_$shipname
		puthelp "PRIVMSG $nick : Removed $shipname"
	}
	if {$cmd eq "tf"} {
		set fleet [lindex [split $rest] 2]
		set fleetassignment([string tolower $shipname]) [string tolower $fleet]
		set taskforces([string tolower $fleet]) $fleet
		puthelp "PRIVMSG $nick : Assigigned $shipname TO $fleet"
	}
	return 1
}

bind pubm - "#* *" logger:text
proc logger:text {nick uhost handle chan text} {
	global shiplist
	if {[string tolower $chan] != "#reflections_command" && [string tolower $chan] != "#reflections_fleethq" && [string tolower $chan] != "#reflections_sensorgrid"} {
	set originship $shiplist([string tolower [string range $chan 13 [string length $chan]]])
  if {[isop $nick $chan] == "1"} {
    set who "$originship - Host $nick says:"
  } elseif {[ishalfop $nick $chan] == "1"} {
    set who "$originship - Host $nick says:"
  } else {
    set who "$originship - $nick says:"
  }
  logger:save $who $text
	}
}

### Secondary Commands
proc logger:save {who text} {
  global logger

  set log "[open "$logger(dir)JointLog.log" a]"
  puts $log "[logger:strip $who]\r"
  puts $log "[logger:strip $text]\r";
  puts $log "\r"
  close $log
}

### Tertiary Commands
proc logger:strip {text} {
  global logger numversion
  if {$logger(strip) == "1"} {
    if {$numversion >= "1061700"} {
      set text "[stripcodes bcruag $text]"
    } else {
      regsub -all -- {\002,\003([0-9][0-9]?(,[0-9][0-9]?)?)?,\017,\026,\037} $text "" text
    }
  }
  return $text
}