##################
## Module Name     --  websocket
## Original Author --  Emmanuel Frecon - emmanuel@sics.se
## Descripcion:
##
##    Version recortada del paquete websocket, debido a necesidades
##    especificas
##
##################

package require Tcl 8.5

package require http 2.7;  # Need keepalive!
package require sha1
package require base64

namespace eval ::winix::websocket {
    variable WS
    if { ! [info exists WS] } {
	array set WS {
	    loglevel       "warn"
	    maxlength      16777216
	    ws_magic       "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
	    ws_version     13
	    id_gene        0
	    -keepalive     30
	    -ping          ""
	}
	variable libdir [file dirname [file normalize [info script]]]
    }
}

proc ::winix::websocket::Disconnect { sock } {
    variable WS

    set varname [namespace current]::Connection_$sock
    upvar \#0 $varname Connection

    if { $Connection(liveness) ne "" } {
	after cancel $Connection(liveness)
    }
    Push $sock disconnect "Disconnected from remote end"
    catch {::close $sock}
    unset $varname
}

proc ::winix::websocket::close { sock { code 1000 } { reason "" } } {
    variable WS

    set varname [namespace current]::Connection_$sock
    if { ! [info exists $varname] } {
	return -code error "$sock is not a WebSocket"
    }
    upvar \#0 $varname Connection

    if { $Connection(state) eq "CLOSED" } {
	return
    }

    ::winix::consola_mensaje "websocket::close cerrando, se puso state en CLOSED" 9
    for { set x [ expr [info level] ]} { $x > 0 } { incr x -1 } {
	    ::winix::consola_mensaje "websocket::close $x: [ info level $x ]" 9
    }
    set Connection(state) CLOSED

    if { $code == "" || ![string is integer $code] } {
	send $sock 8
	Push $sock close {}
    } else {
	if { $reason eq "" } {
	    set reason [string map \
			    { 1000 "Normal closure" \
			      1001 "Endpoint going away" \
			      1002 "Protocol error" \
			      1003 "Received incompatible data type" \
			      1006 "Abnormal closure" \
			      1007 "Received data not consistent with type" \
			      1008 "Policy violation" \
			      1009 "Received message too big" \
			      1010 "Missing extension" \
			      1011 "Unexpected condition" \
			      1015 "TLS handshake error" } $code]
	}
	set msg [binary format Su $code]
	append msg [encoding convertto utf-8 $reason]
	set msg [string range $msg 0 124];  # Cut answer to make sure it fits!
	send $sock 8 $msg
	Push $sock close [list $code $reason]
    }
    
    Disconnect $sock
}


# ::websocket::Push -- Push event or data to handler
#
#       Every WebSocket is associated to a handler that will be
#       notified upon reception of data, but also upon important
#       events within the library or events resulting from control
#       messages sent by the remote end.  This procedure calls this
#       handler, catching all errors that might occur within the
#       handler.  The types that the library pushes out via this
#       callback are:
#       text       Text complete message
#       binary     Binary complete message
#       connect    Notification of successful connection to server
#       disconnect Disconnection from remote end.
#       close      Pending closure of connection
#
# Arguments:
#	sock	WebSocket that was taken over or created by this library
#	type	Type of the event
#	msg	Data of the event.
#       handler Use this command to push back instead of handler at WebSocket
#
# Results:
#       None.
#
# Side Effects:
#       None.
proc ::winix::websocket::Push { sock type msg { handler "" } } {
    variable WS

    # If we have not specified a handler, which is in most cases, pick
    # up the handler from the array that contains all WS-relevant
    # information.
    if { $handler eq "" } {
	set varname [namespace current]::Connection_$sock
	if { ! [info exists $varname] } {
	    return -code error "$sock is not a WebSocket"
	}
	upvar \#0 $varname Connection
	set handler $Connection(handler)
    }
    ::winix::consola_mensaje "Manejador: $handler" 2
    ::winix::consola_mensaje "Socket   : $sock" 2
    ::winix::consola_mensaje "Type     : $type" 2
    ::winix::consola_mensaje "Mensaje  : $msg" 2
    set res ""
#    if { [catch {eval [concat $handler [list $sock $type $msg]]} res] } {
#    	::winix::consola_mensaje "Error en el manejador de eventos de websocket: $res" 2
#    }
    eval [concat $handler [list $sock $type $msg]]
    
    ::winix::consola_mensaje "Ya lo procese: $res" 2
}


# ::websocket::Ping -- Send a ping
#
#       Sends a ping at regular intervals to keep the connection alive
#       and prevent equipment to close it due to inactivity.
#
# Arguments:
#	sock	WebSocket that was taken over or created by this library
#
# Results:
#       None.
#
# Side Effects:
#       None.
proc ::winix::websocket::Ping { sock } {
    variable WS

    set varname [namespace current]::Connection_$sock
    if { ! [info exists $varname] } {
	return -code error "$sock is not a WebSocket"
    }
    upvar \#0 $varname Connection

    # Reschedule at once to get around any possible problem with ping
    # sending.
    Liveness $sock

    # Now send a ping, which will trigger a pong from the
    # (well-behaved) client.
    send $sock ping $Connection(-ping)

}

# ::websocket::Liveness -- Keep connections alive
#
#       Keep connections alive (from the server side by construction),
#       as suggested by the specification.  This procedure arranges to
#       send pings after a given period of inactivity within the
#       socket.  This ties to ensure that all equipment keep the
#       connection open.
#
# Arguments:
#	sock	Existing Web socket
#
# Results:
#       Return the time to next ping, negative or zero if not relevant.
#
# Side Effects:
#       None.
proc ::winix::websocket::Liveness { sock } {
    variable WS

    set varname [namespace current]::Connection_$sock
    upvar \#0 $varname Connection

    # Keep connection alive by issuing pings.
    if { $Connection(liveness) ne "" } {
	after cancel $Connection(liveness)
    }
    set when [expr {$Connection(-keepalive)*1000}]
    if { $when > 0 } {
	set Connection(liveness) [after $when [namespace current]::Ping $sock]
    } else {
	set Connection(liveness) ""
    }
    return $when
}


proc ::winix::websocket::Type { opcode } {
    variable WS

    array set TYPES {1 text 2 binary 8 close 9 ping 10 pong}
    if { [array names TYPES $opcode] } {
	set type $TYPES($opcode)
    } else {
	set type <opcode-$opcode>
    }

    return $type
}


# ::websocket::test -- Test incoming client connections for WebSocket
#
#       This procedure will test if the connection from an incoming
#       client is the opening of a WebSocket stream.  The socket is
#       not upgraded at once, instead a (temporary) context for the
#       incoming connection is created.  This allows server code to
#       perform a number of actions, if necessary before the WebSocket
#       stream connection goes live.  The test is made by analysing
#       the content of the headers.  Additionally, the procedure
#       checks that there exist a valid handler for the path
#       requested.
#
# Arguments:
#	srvSock	Socket to WebSocket compliant HTTP server
#	cliSock	Socket to incoming connected client.
#	path	Path requested by client at server
#	hdrs	Dictionary list of the HTTP headers.
#	qry	Dictionary list of the HTTP query (if applicable).
#
# Results:
#       1 if this is an incoming WebSocket upgrade request for a
#       recognised path, 0 otherwise.
#
# Side Effects:
#       None.
proc ::winix::websocket::test { srvSock cliSock hdrs cb } {
    variable WS

    if { [llength $hdrs] <= 0 } {
	::winix::consola_mensaje "no hay encabezados" 2
	return 0
    }

    set varname [namespace current]::Server_$srvSock
    if { ! [info exists $varname] } {
	return -code error "$srvSock is not a WebSocket"
    }
    upvar \#0 $varname Server

    # Detect presence of connection and upgrade HTTP headers, together
    # with their proper values.
    set upgrading 0
    set websocket 0
    foreach {k v} $hdrs {
    	::winix::consola_mensaje "Revisando encabezado $k -> $v" 9
	if { [string equal -nocase $k "connection"] && \
		 [string first "upgrade" [string tolower $v]] > -1 } {
		::winix::consola_mensaje "upgrading es 1" 9
	    set upgrading 1
	}
	if { [string equal -nocase $k "upgrade"] && \
		 [string equal -nocase $v "websocket"] } {
		::winix::consola_mensaje "websocket es 1" 9
	    set websocket 1
	}
    }
    
    # Fail early when not upgrading to a websocket.
    if { !$upgrading || !$websocket } {
	::winix::consola_mensaje "No querian subir upgrading $upgrading websocket $websocket ? ?" 9
	return 0
    }

    # If headers point towards a possible websocket...
    set key ""
    set protos {}
    foreach {k v} $hdrs {
	if { [string equal -nocase $k "sec-websocket-key"] } {
	    set key $v
	}
	if { [string equal -nocase $k "sec-websocket-protocol"] } {
	    set protos [split $v ","]
	}
    }

    # We thought we had a websocket, but no security handshake is
    # provided by client. Discard this connection!
    if { $key eq "" } {
	::winix::consola_mensaje "Y mi llave??" 9
	return 0
    }

    # Create a context for the incoming client
    set varname [namespace current]::Client_${srvSock}_${cliSock}
    ::winix::consola_mensaje "Creare una variable llamada $varname, te parece" 9
    upvar \#0 $varname Client
    
    set Client(server) $srvSock
    set Client(sock) $cliSock
    set Client(key) $key
    set Client(accept) ""
    set Client(query) ""
    set Client(path) "/"
    if { $key ne "" } {
	set sec ${key}$WS(ws_magic)
	set Client(accept) [::base64::encode [sha1::sha1 -bin $sec]]
	::winix::consola_mensaje "LLaves $key [::base64::encode [sha1::sha1 -bin $sec]]" 9
    }
    set Client(protos) $protos
    set Client(protocol) ""
    set Client(live) $cb

    # Return the context for the incoming client.
    return 1
}


# ::websocket::upgrade -- Upgrade socket to WebSocket in servers
#
#       Upgrade a socket that had been deemed to be an incoming
#       WebSocket connection request (see ::websocket::test) to a true
#       WebSocket.  This procedure will send the necessary connection
#       handshake to the client, arrange for the relevant callbacks to
#       be made during the life of the WebSocket and mediate of the
#       incoming request via a special "request" message.
#
# Arguments:
#	sock	Socket to client.
#
# Results:
#       None.
#
# Side Effects:
#       The socket is kept open and becomes a WebSocket, pushing out
#       callbacks as explained in ::websocket::takeover and accepting
#       messages as explained in ::websocket::send.
proc ::winix::websocket::upgrade { sock } {
    variable WS

    set clients [info vars [namespace current]::Client_*_${sock}]
    ::winix::consola_mensaje "Clientes de websocket [info vars [namespace current]::Client_*]" 9
    if { [llength $clients] == 0 } {
	return -code error "$sock is not a WebSocket client"
    }

    set c [lindex $clients 0];   # Should only be one really...
    upvar \#0 $c Client

    # Write client response header, this is the last time we speak
    # "http"...
    puts $sock "HTTP/1.1 101 Switching Protocols"
    puts $sock "Upgrade: websocket"
    puts $sock "Connection: Upgrade"
    puts $sock "Sec-WebSocket-Accept: $Client(accept)"
    if { $Client(protocol) != "" } {
	puts $sock "Sec-WebSocket-Protocol: $Client(protocol)"
    }
    puts $sock ""
    flush $sock

    ::winix::consola_wss_salida "HTTP/1.1 101 Switching Protocols" limpiar
    ::winix::consola_wss_salida "Upgrade: websocket"
    ::winix::consola_wss_salida "Connection: Upgrade"
    ::winix::consola_wss_salida "Sec-WebSocket-Accept: $Client(accept)"
    if { $Client(protocol) != "" } {
	::winix::consola_wss_salida "Sec-WebSocket-Protocol: $Client(protocol)"
    }
    
    # Make the socket a server websocket
    takeover $sock $Client(live) 1

    # Tell the websocket handler that we have a new incoming
    # request. We mediate this through the "message" part, which in
    # this case is composed of a list containing the URL and the query
    # (itself as a list).  Implementation is rather ugly since we call
    # the hidden method in the websocket code!
#    Push $sock request [list $Client(path) $Client(query)]

    # Get rid of the temporary client state
    unset $c
}


# ::websocket::live -- Register WebSocket callbacks for servers
#
#       This procedure registers callbacks that will be performed on a
#       WebSocket compliant server whenever a client connects to a
#       matching path and protocol.
#
# Arguments:
#	sock	Socket to known WebSocket compliant HTTP server.
#	path	glob-style path to match in client.
#	cb	command to callback (same args as ::websocket::takeover)
#	proto	Application protocol
#
# Results:
#       None.
#
# Side Effects:
#       None.
proc ::winix::websocket::live { sock path cb { proto "*" } } {
    variable WS

    set varname [namespace current]::Server_$sock
    if { ! [info exists $varname] } {
	return -code error "$sock is not a WebSocket"
    }
    upvar \#0 $varname Server

    lappend Server(live) $path $cb $proto
}


# ::webserver::server -- Declare WebSocket server
#
#       This procedure registers the (accept) socket passed as an
#       argument as the identifier for an HTTP server that is capable
#       of doing WebSocket.
#
# Arguments:
#	sock	Socket on which the server accepts incoming connections.
#
# Results:
#       Return the socket.
#
# Side Effects:
#       None.
proc ::winix::websocket::server { sock } {
    variable WS

    set varname [namespace current]::Server_$sock
    upvar \#0 $varname Server
    set Server(sock) $sock
    set Server(live) {}

    return $sock
}


# ::websocket::send -- Send message or fragment to remote end.
#
#       Sends a fragment or a control message to the remote end of the
#       WebSocket. The type of the message is passed as a parameter
#       and can either be an integer according to the specification or
#       one of the following strings: text, binary, ping.  When
#       fragmenting, it is not allowed to change the type of the
#       message between fragments.
#
# Arguments:
#	sock	WebSocket that was taken over or created by this library
#	type	Type of the message (see above)
#	msg	Data of the fragment.
#	final	True if final fragment
#
# Results:
#       Returns the number of bytes sent, or -1 on error.  Serious
#       errors will trigger errors that must be catched.
#
# Side Effects:
#       None.
proc ::winix::websocket::send { sock type {msg ""} {final 1}} {
    variable WS

    set varname [namespace current]::Connection_$sock
    if { ! [info exists $varname] } {
	return -code error "$sock is not a WebSocket"
    }
    upvar \#0 $varname Connection

    # Refuse to send if not connected
    if { $Connection(state) ne "CONNECTED" } {
	return -1
    }

    # Determine opcode from type, i.e. text, binary or ping. Accept
    # integer opcodes for internal use or for future extensions of the
    # protocol.
    set opcode -1;
    if { [string is integer $type] } {
	set opcode $type
    } else {
	switch -glob -nocase -- $type {
	    t* {
		# text
		set opcode 1
	    }
	    b* {
		# binary
		set opcode 2
	    }
	    p* {
		# ping
		set opcode 9
	    }
	}
    }

    if { $opcode < 0 } {
	return -code error \
	    "Unrecognised type, should be one of text, binary, ping or\
             a protocol valid integer"
    }

    # Refuse to continue if different from last type of message.
    if { $Connection(write:opcode) > 0 } {
	if { $opcode != $Connection(write:opcode) } {
	    return -code error \
		"Cannot change type of message under continuation!"
	}
	set opcode 0;    # Continuation
    } else {
	set Connection(write:opcode) $opcode
    }

    # Encode text
    set type [Type $Connection(write:opcode)]
    if { $Connection(write:opcode) == 1 } {
	set msg [encoding convertto utf-8 $msg]
    }

    # Reset continuation state once sending last fragment of message.
    if { $final } {
	set Connection(write:opcode) -1
    }

    # Start assembling the header.
    set header [binary format c [expr {!!$final << 7 | $opcode}]]

    # Append the length of the message to the header. Small lengths
    # fit directly, larger ones use the markers 126 or 127.  We need
    # also to take into account the direction of the socket, since
    # clients shall randomly mask data.
    set mlen [string length $msg]
    if { $mlen < 126 } {
	set plen [string length $msg]
    } elseif { $mlen < 65536 } {
	set plen 126
    } else {
	set plen 127
    }

    # Set mask bit and push regular length into header.
    if { [string is true $Connection(server)] } {
	append header [binary format c $plen]
	set dst "client"
    } else {
	append header [binary format c [expr {1 << 7 | $plen}]]
	set dst "server"
    }

    # Appends "longer" length when the message is longer than 125 bytes
    if { $mlen > 125 } {
	if { $mlen < 65536 } {
	    append header [binary format Su $mlen]
	} else {
	    append header [binary format Wu $mlen]
	}
    }

    # Add the masking key and perform client masking whenever relevant
    if { [string is false $Connection(server)] } {
	set mask [expr {int(rand()*(1<<32))}]
	append header [binary format Iu $mask]
	set msg [Mask $mask $msg]
    }
    
    # Send the (masked) frame
    if { [catch {
	puts -nonewline $sock $header$msg;
	flush $sock;} err]} {
	close $sock 1001
	return -1
    }

    # Keep socket alive at all times.
    Liveness $sock

    if { [string is true $final] } {
    } else {
    }
    return [string length $header$msg]
}


# ::websocket::Mask -- Mask data according to RFC
#
#       XOR mask data with the provided mask as described in the RFC.
#
# Arguments:
#	mask	Mask to use to mask the data
#	dta	Bytes to mask
#
# Results:
#       Return the mask bytes, i.e. as many bytes as the data that was
#       given to this procedure, though XOR masked.
#
# Side Effects:
#       None.
proc ::winix::websocket::Mask { mask dta } {
    variable WS

    # Format data as a list of 32-bit integer
    # words and list of 8-bit integer byte leftovers.  Then unmask
    # data, recombine the words and bytes, and return
    binary scan $dta I*c* words bytes

    set masked_words {}
    set masked_bytes {}
    for {set i 0} {$i < [llength $words]} {incr i} {
	lappend masked_words [expr {[lindex $words $i] ^ $mask}]
    }
    for {set i 0} {$i < [llength $bytes]} {incr i} {
	lappend masked_bytes [expr {[lindex $bytes $i] ^
				    ($mask >> (24 - 8 * $i))}]
    }

    return [binary format I*c* $masked_words $masked_bytes]
}


# ::websocket::Receiver -- Receive (framed) data from WebSocket
#
#       Received framed data from a WebSocket, recontruct all
#       fragments to a complete message whenever the final fragment is
#       received and calls the handler associated to the WebSocket
#       with the content of the message once it has been
#       reconstructed.  Interleaved control frames are also passed
#       further to the handler.  This procedure also automatically
#       responds to ping by pongs.
#
# Arguments:
#	sock	WebSocket that was taken over or created by this library
#
# Results:
#       None.
#
# Side Effects:
#       Read a frame from the socket, possibly blocking while reading.
proc ::winix::websocket::Receiver { sock } {
    variable WS

    set varname [namespace current]::Connection_$sock
    if { ! [info exists $varname] } {
	::winix::consola_mensaje "websocket::receiver no esta la variable!" 9
	return -code error "$sock is not a WebSocket"
    }
    upvar \#0 $varname Connection

    # Keep connection alive by issuing pings.
    Liveness $sock

    # Get basic header.  Abort if reserved bits are set, unexpected
    # continuation frame, fragmented or oversized control frame, or
    # the opcode is unrecognised.
    if [catch {read $sock 2} dta] {
	if {[chan eof $sock]} {
		set dta "Socket closed."
		::winix::consola_wss_entrada "websocket::receiver chan eof $sock!"
	}
	::winix::consola_wss_entrada "websocket::receiver aguas el problema es $dta"
	close $sock 1001
	return
    } else {
		::winix::consola_wss_entrada ".$dta."
	    if { [string length $dta] != 2 } {
		catch {read $sock} odta
		::winix::consola_wss_entrada ".$dta.$odta."
		return
	    }
    }
    ::winix::consola_wss_entrada $dta
    binary scan $dta Su header
    set opcode [expr {$header >> 8 & 0xf}]
    set mask [expr {$header >> 7 & 0x1}]
    set len [expr {$header & 0x7f}]
    set reserved [expr {$header >> 12 & 0x7}]
    if { $reserved \
	     || ($opcode == 0 && $Connection(read:mode) eq "") \
	     || ($opcode > 7 && (!($header & 0x8000) || $len > 125)) \
	     || [lsearch {0 1 2 8 9 10} $opcode] < 0 } {
	# Send close frame, reason 1002: protocol error
	::winix::consola_mensaje "websocket::receiver verifica opcode $opcode (error de protocolo)" 9
	close $sock 1002
	return
    }
    # Determine the opcode for this frame, i.e. handle continuation of
    # frames. Control frames must not be split/continued (RFC6455 5.5).
    # No multiplexing here!
    if { $Connection(read:mode) eq "" } {
	set Connection(read:mode) $opcode
    } elseif { $opcode == 0 } {
	set opcode $Connection(read:mode)
    }


    # Get the extended length, if present
    if { $len == 126 } {
	if { [catch {read $sock 2} dta] || [string length $dta] != 2 } {
	::winix::consola_mensaje "websocket::receiver no pude leer longitud del socket $dta" 9
	    close $sock 1001
	    return
	}
	binary scan $dta Su len
    } elseif { $len == 127 } {
	if { [catch {read $sock 8} dta] || [string length $dta] != 8 } {
	::winix::consola_mensaje "websocket::receiver no pude leer longitud del socket $dta" 9
	    close $sock 1001
	    return
	}
	binary scan $dta Wu len
    }


    # Control frames use a separate buffer, since they can be
    # interleaved in fragmented messages.
    if { $opcode > 7 } {
	# Control frames should be shorter than 125 bytes
	if { $len > 125 } {
	::winix::consola_mensaje "websocket::receiver frame de control muy largo" 9
	    close $sock 1009
	    return
	}
	set oldmsg $Connection(read:msg)
	set Connection(read:msg) ""
    } else {
	# Limit the maximum message length
	if { [string length $Connection(read:msg)] + $len > $WS(maxlength) } {
	    # Send close frame, reason 1009: frame too big
	    close $sock 1009 "Limit $WS(maxlength) exceeded"
	::winix::consola_mensaje "websocket::receiver frame de close muy largo" 9
	    return
	}
    }

    if { $mask } {
	# Get mask and data.  Format data as a list of 32-bit integer
        # words and list of 8-bit integer byte leftovers.  Then unmask
	# data, recombine the words and bytes, and append to the buffer.
	if { [catch {read $sock 4} dta] || [string length $dta] != 4 } {
	::winix::consola_mensaje "websocket::receiver no pude leer mascara $dta" 9
	    close $sock 1001
	    return
	}
	binary scan $dta Iu mask
	if { [catch {read $sock $len} bytes] } {
	    close $sock 1001
	    return
	}
	append Connection(read:msg) [Mask $mask $bytes]
    } else {
	if { [catch {read $sock $len} bytes] \
		 || [string length $bytes] != $len } {
	::winix::consola_mensaje "websocket::receiver contenido del fragmento no pudo ser leido $bytes" 9
	    close $sock 1001
	    return
	}
	append Connection(read:msg) $bytes
    }

    if { [string is true $Connection(server)] } {
	set dst "client"
    } else {
	set dst "server"
    }
    set type [Type $Connection(read:mode)]

    # If the FIN bit is set, process the frame.
    if { $header & 0x8000 } {
	::winix::consola_mensaje "websocket::receiver Received $len long $type final fragment from $dst" 9
	switch $opcode {
	    1 {
		# Text: decode and notify handler
		Push $sock text \
		    [encoding convertfrom utf-8 $Connection(read:msg)]
	    }
	    2 {
		# Binary: notify handler, no decoding
		Push $sock binary $Connection(read:msg)
	    }
	    8 {
		# Close: decode, notify handler and close frame.
		if { [string length $Connection(read:msg)] >= 2 } {
		    binary scan [string range $Connection(read:msg) 0 1] Su \
			reason
		    set msg [encoding convertfrom utf-8 \
				 [string range $Connection(read:msg) 2 end]]
	::winix::consola_mensaje "websocket::receiver cerrando por switch 8" 9
		    close $sock $reason $msg
		} else {
	::winix::consola_mensaje "websocket::receiver cerrando por switch 8 sin razon" 9
		    close $sock 
		}
		return
	    }
	    9 {
		# Ping: send pong back and notify handler since this
		# might contain some data.
		send $sock 10 $Connection(read:msg)
		Push $sock ping $Connection(read:msg)
	    }
	}

	# Prepare for next frame.
	if { $opcode < 8 } {
	    # Reinitialise
	    set Connection(read:msg) ""
	    set Connection(read:mode) ""
	} else {
	    set Connection(read:msg) $oldmsg
	    if {$Connection(read:mode) eq $opcode} {
		# non-interjected control frame, clear mode
		set Connection(read:mode) ""
	    }
	}
    } else {
    }
}


# ::websocket::New -- Create new websocket connection context
#
#       Create a blank new websocket connection context array, the
#       connection is placed in the state "CONNECTING" meaning that it
#       is not ready for action yet.
#
# Arguments:
#	sock	Socket to remote end
#	handler	Handler callback
#	server	Is this a server or a client socket
#
# Results:
#       Return the internal name of the array storing connection
#       details.
#
# Side Effects:
#       This procedure will reinitialise the connection information
#       for the socket if it was already known.  This is on purpose
#       and by design, but worth noting.
proc ::winix::websocket::New { sock handler { server 0 } } {
    variable WS

    set varname [namespace current]::Connection_$sock
    upvar \#0 $varname Connection
    
    set Connection(sock) $sock
    set Connection(handler) $handler
    set Connection(server) $server

    set Connection(peername) 0.0.0.0
    set Connection(sockname) 127.0.0.1
    
    set Connection(read:mode) ""
    set Connection(read:msg) ""
    set Connection(write:opcode) -1
    set Connection(state) CONNECTING
    set Connection(liveness) ""
    
    # Arrange for keepalive to be zero, i.e. no pings, when we are
    # within a client.  When in servers, take the default from the
    # library.  In any case, this can be configured, which means that
    # even clients can start sending pings when nothing has happened
    # on the line if necessary.
    if { [string is true $server] } {
	set Connection(-keepalive) $WS(-keepalive)
    } else {
	set Connection(-keepalive) 0
    }
    set Connection(-ping) $WS(-ping)

    return $varname
}


# ::websocket::takeover -- Take over an existing socket.
#
#       Take over an existing opened socket to implement sending and
#       receiving WebSocket framing on top of the socket.  The
#       procedure takes a handler, i.e. a command that will be called
#       whenever messages, control messages or other important
#       internal events are received or occur.
#
# Arguments:
#	sock	Existing opened socket.
#	handler	Command to call on events and incoming messages.
#	server	Is this a socket within a server, i.e. towards a client.
#
# Results:
#       None.
#
# Side Effects:
#       None.
proc ::winix::websocket::takeover { sock handler { server 0 } } {
    variable WS

    # Create (or update) connection
    set varname [New $sock $handler $server]
    upvar \#0 $varname Connection
    set Connection(state) CONNECTED

    ::winix::consola_mensaje "websocket::takeover Puse estado en CONNECTED" 9
    
    # Gather information about local and remote peer.
    if { [catch {fconfigure $sock -peername} sockinfo] == 0 } {
	set Connection(peername) [lindex $sockinfo 1]
	if { $Connection(peername) eq "" } {
	    set Connection(peername) [lindex $sockinfo 0]
	}
    }
    if { [catch {fconfigure $sock -sockname} sockinfo] == 0 } {
	set Connection(sockname) [lindex $sockinfo 1]
	if { $Connection(sockname) eq "" } {
	    set Connection(sockname) [lindex $sockinfo 0]
	}
    }

    # Listen to incoming traffic on socket and make sure we ping if
    # necessary.
    fconfigure $sock -translation binary -blocking on
    fileevent $sock readable [list [namespace current]::Receiver $sock]
    Liveness $sock

    ::winix::consola_mensaje "websocket::takeover $sock has been registered as a\
                   [expr $server?\"server\":\"client\"] WebSocket" 9
    
}


# ::websocket::Connected -- Handshake and framing initialisation
#
#       Performs the security handshake once connection to a remote
#       WebSocket server has been established and handshake properly.
#       On success, start listening to framed data on the socket, and
#       mediate the callers about the connection and the application
#       protocol that was chosen by the server.
#
# Arguments:
#	opener	Temporary HTTP connection opening object.
#	sock	Socket connection to server, empty to pick from HTTP state array
#	token	HTTP state array.
#
# Results:
#       None.
#
# Side Effects:
#       None.
proc ::winix::websocket::Connected { opener sock token } {
    variable WS

    upvar \#0 $opener OPEN

    # Dig into the internals of the HTTP library for the socket if
    # none present as part of the arguments (ugly...)
    if { $sock eq "" } {
	set sock [HTTPSocket $token]
	if { $sock eq "" } {
	    return 0
	}
    }

    if { [::http::ncode $token] == 101 } {
	array set HDR [::http::meta $token]

	# Extact security handshake, check against what was expected
	# and abort in case of mismatch.
	if { [array names HDR Sec-WebSocket-Accept] ne "" } {
	    # Compute security handshake
	    set sec $OPEN(nonce)$WS(ws_magic)
	    set accept [base64::encode [sha1::sha1 -bin $sec]]
	    if { $accept ne $HDR(Sec-WebSocket-Accept) } {
		::http::reset $token error
		unset $opener
		Disconnect $sock
		return 0
	    }
	}

	# Extract application protocol information to pass further to
	# handler.
	set proto ""
	if { [array names HDR Sec-WebSocket-Protocol] ne "" } {
	    set proto $HDR(Sec-WebSocket-Protocol)
	}

	# Remove the socket from the socketmap inside the http
	# library.  THIS IS UGLY, but the only way to make sure we
	# really can take over the socket and make sure the library
	# will open A NEW socket, even towards the same host, at a
	# later time.
	if { [info vars ::http::socketmap] ne "" } {
	    foreach k [array names ::http::socketmap] {
		if { $::http::socketmap($k) eq $sock } {
		    unset ::http::socketmap($k)
		}
	    }
	} else {
	}

	# Takeover the socket to create a connection and mediate about
	# connection via the handler.
	takeover $sock $OPEN(handler)
	Push $sock connect $proto;  # Tell the handler which
				      # protocol was chosen.
    } else {
	Push \
	    "" \
	    error \
	    "Protocol error during WebSocket connection with $OPEN(url)" \
	    $OPEN(handler)
    }

    ::http::cleanup $token
    unset $opener;   # Always unset the temporary connection opening
		     # array
}


# ::websocket::Finished -- Pass further on HTTP connection finalisation
#
#       Pass further to Connected whenever the HTTP operation has
#       been finished as implemented by the HTTP package.
#
# Arguments:
#	opener	Temporary HTTP connection opening object.
#	sock	Socket connection to server, empty to pick from HTTP state array
#	token	HTTP state array.
#
# Results:
#       None.
#
# Side Effects:
#       None.
proc ::winix::websocket::Finished { opener token } {
    Connected $opener "" $token
}


# ::websocket::Timeout -- Timeout an HTTP connection
#
#       Reimplementation of the timeout facility from the HTTP package
#       to be able to cleanup internal state properly and mediate to
#       the handler.
#
# Arguments:
#	opener	Temporary HTTP connection opening object.
#
# Results:
#       None.
#
# Side Effects:
#       Reset the HTTP connection, which will (probably) close the
#       socket.
proc ::winix::websocket::Timeout { opener } {
    variable WS

    if { [info exists $opener] } {
	upvar \#0 $opener OPEN
	
	::http::reset $OPEN(token) "timeout"
	set sock [HTTPSocket $OPEN(token)]
	Push $sock timeout \
	    "Timeout when connecting to $OPEN(url)" $OPEN(handler)
	::http::cleanup $OPEN(token)
	unset $opener
	
	# Destroy connection state, which will also attempt to close
	# the socket.
	if { $sock ne "" } {
	    Disconnect $sock
	    ::winix::consola_mensaje "websocket::Sucedio un timeout en el websocket $sock hilo [ ::thread::id]" 9
	}
    }
}


# ::websocket::HTTPSocket -- Get socket from HTTP token
#
#       Extract the socket used for a given (existing) HTTP
#       connection.  This uses the undocumented index called "sock" in
#       the HTTP state array.
#
# Arguments:
#	token	HTTP token, as returned by http::geturl
#
# Results:
#       The socket to the remote server, or an empty string on errors.
#
# Side Effects:
#       None.
proc ::winix::websocket::HTTPSocket { token } {

    upvar \#0 $token htstate
    if { [array names htstate sock] eq "sock" } {
	return $htstate(sock)
    } else {
	return ""
    }
}


# ::websocket::open -- Open connection to remote WebSocket server
#
#       Open a WebSocket connection to a remote server.  This
#       procedure takes a number of options, which mostly are the
#       options that are supported by the http::geturl procedure.
#       However, there are a few differences described below:
#       -headers  Is supported, but additional headers will be added internally
#       -validate Is not supported, it has no point.
#       -handler  Is used internally, so cannot be specified.
#       -command  Is used internally, so cannot be specified.
#       -protocol Contains a list of app. protocols to handshake with server
#
# Arguments:
#	url	WebSocket URL, i.e. led by ws: or wss:
#	handler	Command to callback on data reception or event occurence
#	args	List of dashled options with their values, as explained above.
#
# Results:
#       Return the socket for use with the rest of the WebSocket
#       library, or an empty string on errors.
#
# Side Effects:
#       None.
proc ::winix::websocket::open { url handler args } {
    variable WS

    # Fool the http library by replacing the ws: (websocket) scheme
    # with the http, so we can use the http library to handle all the
    # initial handshake.
    set hturl [string map -nocase {ws: http: wss: https:} $url]

    # Start creating a command to call the http library.
    set cmd [list ::http::geturl $hturl]

    # Control the geturl options that we can blindly pass to the
    # http::geturl call. We basically remove -validate, which has no
    # point and stop -handler which we will be using internally.  We
    # restrain the use of -timeout, implementing the timeout ourselves
    # to avoid the library to close the socket to the server.  We also
    # intercept the headers since we will be adding WebSocket protocol
    # information as part of the headers.
    set protos {}
    set timeout -1
    array set HDR {}
    foreach { k v } $args {
	set allowed 0
	foreach opt {bi* bl* ch* he* k* m* prog* prot* qu* s* ti* ty*} {
	    if { [string match -nocase $opt [string trimleft $k -]] } {
		set allowed 1
	    }
	}
	if { ! $allowed } {
	    return -code error "$k is not a recognised option"
	}
	switch -nocase -glob -- [string trimleft $k -] {
	    he* {
		# Catch the headers, since we will be adding a few
		# ones by hand.
		array set HDR $v
	    }
	    prot* {
		# New option -protocol to support the list of
		# application protocols that the client accepts.
		# -protocol should be a list.
		set protos $v
	    }
	    ti* {
		# We implement the timeout ourselves to be able to
		# properly cleanup.
		if { [string is integer $v] && $v > 0 } {
		    set timeout $v
		}
	    }
	    default {
		# Any other allowed option will simply be passed
		# further to the http::geturl call, to benefit from
		# all its facilities.
		lappend cmd $k $v
	    }
	}
    }

    # Create an HTTP connection object that will contain all necessary
    # internal data until the connection has been a success or until
    # it failed.
    set varname [namespace current]::opener_[incr WS(id_gene)]
    upvar \#0 $varname OPEN
    set OPEN(url) $url
    set OPEN(handler) $handler
    set OPEN(nonce) ""

    # Construct the WebSocket part of the header according to RFC6455.
    # The NONCE should be randomly chosen for each new connection
    # established
    set HDR(Connection) "Upgrade"
    set HDR(Upgrade) "websocket"
    for { set i 0 } { $i < 4 } { incr i } {
        append OPEN(nonce) [binary format Iu [expr {int(rand()*4294967296)}]]
    }
    set OPEN(nonce) [::base64::encode $OPEN(nonce)]
    set HDR(Sec-WebSocket-Key) $OPEN(nonce)
    set HDR(Sec-WebSocket-Protocol) [join $protos ", "]
    set HDR(Sec-WebSocket-Version) $WS(ws_version)
    lappend cmd -headers [array get HDR]

    # Add our own handler to intercept the socket once connection has
    # been opened and established properly and make sure we keep alive
    # the socket so we can continue using it. In practice, what gets
    # called is the command that is specified by -command, even though
    # we would like to intercept this earlier on.  This has to do with
    # the internals of the HTTP package.
    lappend cmd \
	-handler [list [namespace current]::Connected $varname] \
	-command [list [namespace current]::Finished $varname] \
	-keepalive 1

    # Now open the connection to the remote server using the HTTP
    # package...
    set sock ""
    if { [catch {eval $cmd} token] } {
    } else {
	set sock [HTTPSocket $token]
	if { $sock ne "" } {
	    set varname [New $sock $handler]
	    if { $timeout > 0 } {
		set OPEN(timeout) \
		    [after $timeout [namespace current]::Timeout $varname]
	    }
	} else {
	    Timeout $varname
	}
    }

    return $sock
}


# ::websocket::conninfo -- Connection information
#
#       Provide callers with some introspection facilities in order to
#       get some semi-internal data about an existing websocket.  It
#       returns the following pieces of information:
#       peername   - name or IP of remote end
#       (sock)name - name or IP of local end
#       closed     - 1 if closed, 0 otherwise
#       client     - 1 if client websocket
#       server     - 1 if server websocket
#       type       - the string "server" or "client", depending on the type.
#       handler    - callback registered from websocket.
#       state      - current state of websocket, one of CONNECTING, CONNECTED or
#                    CLOSED.
#
# Arguments:
#	sock	WebSocket that was taken over or created by this library
#	what	What piece of information to get, see above for details.
#
# Results:
#       Return the value of the information or an empty string.
#
# Side Effects:
#       None.
proc ::winix::websocket::conninfo { sock what } {
    variable WS

    set varname [namespace current]::Connection_$sock
    if { ! [::info exists $varname] } {
        return -code error "$sock is not a WebSocket"
    }
    upvar \#0 $varname Connection
    
    switch -glob -nocase -- $what {
        "peer*" {
            return $Connection(peername)
        }
        "sockname" -
        "name" {
            return $Connection(sockname)
        }
        "close*" {
            return [expr {$Connection(state) eq "CLOSED"}]
        }
        "client" {
            return [string is false $Connection(server)]
        }
        "server" {
            return [string is true $Connection(server)]
        }
        "type" {
            return [expr {[string is true $Connection(server)]?\
			      "server":"client"}]
        }
        "handler" {
            return $Connection(handler)
        }
	"state" {
	    return $Connection(state)
	}
        default {
            return -code error "$what is not a known information piece for\
                                a websocket"
        }
    }
    return "";  # Never reached
}


# ::websocket::find -- Find an existing websocket
#
#       Look among existing websockets for the ones that match the
#       hostname and port number filters passed as parameters.  This
#       lookup takes the remote end into account.
#
# Arguments:
#	host	hostname filter, will also be tried against IP.
#	port	port filter
#
# Results:
#       List of matching existing websockets.
#
# Side Effects:
#       None.
proc ::winix::websocket::find { { host * } { port * } } {
    variable WS

    set socks [list]
    foreach varname [::info vars [namespace current]::Connection_*] {
        upvar \#0 $varname Connection
        foreach {ip hst prt} $Connection(peername) break
        if { ([string match $host $ip] || [string match $host $hst]) \
                 && [string match $port $prt] } {
            lappend socks $Connection(sock)
        }
    }

    return $socks
}


# ::websocket::configure -- Configure an existing websocket.
#
#       Takes a number of dash-led options to configure the behaviour
#       of an existing websocket.  The recognised options are:
#       -keepalive  The frequency of the keepalive pings.
#       -ping       The text sent during pings.
#
# Arguments:
#	sock	WebSocket that was taken over or created by this library
#	args	Dash-led options and their (new) value.
#
# Results:
#       None.
#
# Side Effects:
#       None.
proc ::winix::websocket::configure { sock args } {
    variable WS

    set varname [namespace current]::Connection_$sock
    if { ! [info exists $varname] } {
	return -code error "$sock is not a WebSocket"
    }
    upvar \#0 $varname Connection

    foreach { k v } $args {
	set allowed 0
	foreach opt {k* p*} {
	    if { [string match -nocase $opt [string trimleft $k -]] } {
		set allowed 1
	    }
	}
	if { ! $allowed } {
	    return -code error "$k is not a recognised option"
	}
	switch -nocase -glob -- [string trimleft $k -] {
	    k* {
		# Change keepalive
		set Connection(-keepalive) $v
		Liveness $sock;  # Change at once.
	    }
	    p* {
		# Change ping, i.e. text used during the automated pings.
		set Connection(-ping) $v
	    }
	}
    }
}
