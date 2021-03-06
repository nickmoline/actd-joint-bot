array set shiplist {}
array set taskforces {}
array set fleetassignment {}

# Set the following to the prefix you want to use for this joint
set jointchanprefix "#Wide_"

set jointprefixlen [string length $jointchanprefix] 

#;;; Where the logs will be saved.
set logger(dir) "logs/"

#;;; Strip codes?
#;;; 0 = save codes\colors
#;;; 1 = no save codes\colors
set logger(strip) "1"

#;;; Save by Day, Week, Month or Disable?
set logger(time) "Month"

proc initialize_ship_channels {} {
	global jointchanprefix
	global jointprefixlen
	global shiplist

	initialize_ship_chan "Group" "Command"
	initialize_ship_chan "Group" "FleetHQ"
	initialize_ship_chan "Group" "SensorGrid"

	if {[array size shiplist] > 0} {
		foreach {key name} [array get shiplist] {
			initialize_ship_chan "Ship" $name
		}
	}
}

proc ship_channel {ship} {
	global jointchanprefix
	set list {}
	
	lappend list $jointchanprefix
	lappend list $ship

	set chan [join $list ""]
	#putlog "$ship Channel Name: $chan"
	return $chan
}

proc initialize_ship_chan {type name} {
	set channame [ship_channel $name]
	if {![validchan $channame]} {
		putlog "Creating $type Channel $name : $channame"
		channel add $channame
	}
}

proc message_ship_target {chan targetship message} {
	global shiplist
	global jointchanprefix
	global taskforces
	global fleetassignment
	global jointprefixlen

	set targetchan [ship_channel $targetship]

	if {[string tolower $targetship] eq "all"} {
		set chanlist [lindex [channels]]
		foreach ch $chanlist {
			if {[parse_joint_channel $ch] != "fleethq" && [string tolower $ch] != [string tolower $chan]} {
				putquick "PRIVMSG $ch : $message"
			}
		}
	} elseif {[validchan $targetchan]} {
		putquick "PRIVMSG $targetchan : $message"
		if {[string tolower $targetship] != "sensorgrid"} {
			putquick "PRIVMSG [ship_channel "SensorGrid"] : $message"
		}
	} else {
		set foundvalid 0
		foreach name [array names fleetassignment] {
			if {$fleetassignment($name) eq $targetship} {
				set foundvalid 1
				putquick "PRIVMSG [ship_channel $name] : $message"
			}
		}
		if {$foundvalid eq 0} {
			putquick "PRIVMSG [ship_channel "Command"] : $message"
		}
		putquick "PRIVMSG [ship_channel "SensorGrid"] : $message"
	}
}


bind pub - "COM:" relay_message
bind pub - "COMM:" relay_message
bind pub - "COM" relay_message
bind pub - "COMM" relay_message

proc relay_message {nick uhost hand chan rest} {
	set target [string tolower [lindex [split $rest] 0]]
	set chan [string tolower $chan]

	global shiplist
	global taskforces
	global fleetassignment
	global jointchanprefix
	
	if {[parse_joint_channel $chan] != "fleethq" && [parse_joint_channel $chan] != "sensorgrid"} {
		set originship [get_ship_name $chan]
		#set targetship [string range $target 0 [expr [string length $target] - 2]]
		set targetship [string trimright $target :]

		putlog "$nick sent COM MESSAGE TO $targetship of $rest"
		message_ship_target $chan $targetship "<$originship - $nick> @COM: $rest"
	}
	return 1
}

proc relay_action_message {nick chan prefix message} {
	global shiplist
	set chanlist [channels]
	set originship [get_ship_name $chan]
	global jointchanprefix

	if {[parse_joint_channel $chan] eq "command"} {
		relay_global_action_message $nick $chan $prefix $message
	} else {
		message_ship_target $chan "sensorgrid" "<$originship - $nick> $prefix: $message"
	}

	return 1
}

proc relay_global_action_message {nick chan prefix message} {
	message_ship_target $chan "all" "<$nick> $prefix: $message"
	putlog "$nick sent $prefix to all channels: $message"
	logger:helper $chan $nick "$prefix: $message"
}

bind pub - "ACTION:" relay_action
bind pub - "A:" relay_action

proc relay_action {nick uhost hand chan rest} {
	relay_action_message $nick $chan "ACTION" $rest
}

bind pub - "INFO:" relay_info
bind pub - "I:" relay_info

proc relay_info {nick uhost hand chan rest} {
	relay_action_message $nick $chan "INFO" $rest
}

bind pub - "SCENE:" relay_scene
bind pub - "S:" relay_scene
proc relay_scene {nick uhost hand chan rest} {
	relay_action_message $nick $chan "SCENE" $rest
}


bind pub - "GLOBAL:" relay_global
bind pub - "G:" relay_global
bind pub - "GA:" relay_global
proc relay_global {nick uhost hand chan rest} {
	relay_global_action_message $nick $chan "GLOBAL ACTION" $rest
}

bind pub - "GI:" relay_global_info
proc relay_global_info {nick uhost hand chan rest} {
	relay_global_action_message $nick $chan "GLOBAL INFO" $rest
}

bind pub - "GS:" relay_global_scene
proc relay_global_scene {nick uhost hand chan rest} {
	relay_global_action_message $nick $chan "GLOBAL SCENE" $rest
}


bind join - "*" actdjoint_join_main
proc actdjoint_join_main {nick uhost hand chan} {
	global botnick
	if {$nick==$botnick} {
		actdjoint_set_topics $chan
	}
}

bind mode - "*" actdjoint_mode_main
proc actdjoint_mode_main {nick uhost hand chan mode target} {
	global botnick
	if {$target == $botnick && $mode == "+o"} {
		actdjoint_set_topics $chan
	}
}

proc actdjoint_set_topics {chan} {
	if {[botisop $chan]} {
		set chanshort [parse_joint_channel $chan]
		if {$chanshort == "fleethq"} {
			putquick "TOPIC $chan : Fleet Wide OOC"
		} elseif {$chanshort == "sensorgrid"} {
			putquick "TOPIC $chan : Fleet Wide Sensor Grid - All COMMs and actions go here"
		} elseif {$chanshort == "command"} {
			putquick "TOPIC $chan : Fleet Wide Command Center - SMs only"
		} else {
			set shipname [get_ship_name $chan]
			putquick "TOPIC $chan : Fleet Wide Mission Channel for the U.S.S. $shipname"
		}
	}
}

bind need - "% op" needop
proc needop {chan type} {
	global botnick
	putlog "I ($botnick) need op in $chan"
	#putquick "MODE $chan +o $botnick"
	return 1
}

bind msg m "ship" msg_ship
proc msg_ship {nick host handle rest} {
	global shiplist
	global fleetassignment
	global taskforces
	global jointchanprefix
	global jointprefixlen

	initialize_ship_channels

	set cmd [string tolower [lindex [split $rest] 0]]
	set shipname [lindex [split $rest] 1]
	#set shipname $rest
	if {$cmd eq "add"} {
		set shiplist([string tolower $shipname]) $shipname
		initialize_ship_chan "Ship" $shipname
		puthelp "PRIVMSG $nick : Added $shipname"
	}
	if {$cmd eq "del"} {
		unset shiplist([string tolower $shipname])
		channel remove [ship_channel $shipname]
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

proc logger:helper {chan nick text} {
	set originship [get_ship_name $chan]
	if {[isop $nick $chan] == "1"} {
		set who "Host $nick says:"
	} elseif {[ishalfop $nick $chan] == "1"} {
		set who "Host $nick says:"
	} else {
		set who "$nick says:"
	}
	logger:save $originship $who $text
}

bind pubm - "#* *" logger:text
proc logger:text {nick uhost handle chan text} {
    set shipname [parse_joint_channel $chan]
    global shiplist
    if {$shipname != "command" && $shipname != "fleethq" && $shipname != "sensorgrid"} {
    	logger:helper $chan $nick $text
    }
}

### Secondary Commands

proc parse_joint_channel {chan} {
	global shiplist
	global jointchanprefix
	global jointprefixlen

	set originshiplabel [string tolower [string range $chan $jointprefixlen [string length $chan]]]
	return $originshiplabel
}

proc get_ship_name {chan} {
	global shiplist
	global jointchanprefix
	global jointprefixlen

	set chanshort [parse_joint_channel $chan]
	if {$chanshort == "fleethq"} {
		return "Fleet HQ"
	} elseif {$chanshort == "sensorgrid"} {
		return "Sensor Grid"
	} elseif {$chanshort == "command"} {
		return "Command"
	} else {
		return $shiplist($chanshort)
	}
}

proc logger:save {ship who text} {
    global logger
    
    set log "[open "$logger(dir)JointLog.log" a]"
    set shiplog "[open "$logger(dir)$ship.log" a]"
    puts $log "[logger:strip $ship] - [logger:strip $who]\r";
    puts $shiplog "[logger:strip $who]\r";
    puts $log "[logger:strip $text]\r";
    puts $shiplog "[logger:strip $text]\r";
    puts $log "\r"
    puts $shiplog "\r";
    
    close $log
    close $shiplog
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