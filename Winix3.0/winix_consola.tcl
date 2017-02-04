
proc debug { mensaje nivel} {
	puts $mensaje
}

namespace eval winix {
	proc ::winix::inicializa_entorno {} {
		if [ catch { package require Tk } resultado ] {
			::winix::asigna_valor modalidad 	texto 	cargador "Deteccion del sistema grafico"
			::winix::asigna_valor consola_web 	false 	cargador "Deteccion del sistema grafico"
			::winix::consola_mensaje "Se cargo en modo texto. $resultado $::errorInfo"
		} else {
			::winix::asigna_valor modalida grafico cargador "Deteccion del sistema grafico"

			package require Tablelist

			# Minimiza la ventana principal
			wm title . "Consola de servidor de Winix In The Cloud 1.0 - Winix 3.0"

			frame .salida
			text .salida.texto -yscrollcommand { .salida.sb set } -height 10 -width 40
			scrollbar .salida.sb -orient vertical -command { .salida.texto yview}

			frame .entrada
			text .entrada.texto -yscrollcommand { .entrada.sb set } -height 10 -width 40
			scrollbar .entrada.sb -orient vertical -command { .entrada.texto yview}

			frame .wsse
			text .wsse.texto -yscrollcommand { .wsse.sb set } -height 10 -width 40
			scrollbar .wsse.sb -orient vertical -command { .wsse.texto yview}
			
			frame .wsss
			text .wsss.texto -yscrollcommand { .wsss.sb set } -height 10 -width 40
			scrollbar .wsss.sb -orient vertical -command { .wsss.texto yview}
			
			text .estado -bg white -fg red -yscrollcommand { .sv set } -width 70 -font {arial 14 normal} -wrap none
			scrollbar .sv -orient vertical -command { .estado yview}

			button .ok -text "Terminar" -command {
				.ok configure -state disabled
				::thread::broadcast exit
				after 3000 exit
			}
			button .lh -text "Limpiar Historial" -command { 
				.estado delete 0.0 end
			}
			
			frame .conexiones
			::tablelist::tablelist .conexiones.lista \
		        -columns {0 "S"
				  0 "Usuario"
		                  0 "programa"
		                  0 "hilo"
		                  0 "dominio"
		                  0 "ip"
		                  0 "provisionado"} \
        		-yscrollcommand { .conexiones.sb set } \
        		-xscrollcommand { .conexiones.sbx set } \
        		-width 60
        
			scrollbar .conexiones.sb -command { .conexiones.lista yview}
			scrollbar .conexiones.sbx -orient horizontal -command { .conexiones.lista xview}

			frame .consola
			label .consola.t -text "Consola websocket:"
			entry .consola.e -textvar ::winix::consola -vcmd ::winix::consola_websocket -bg white
			
			bind [.conexiones.lista bodytag] <2> "::winix::manda_automata \[ lindex \[.conexiones.lista get active \] 3 \]"
			bind [.conexiones.lista bodytag] <3> "::winix::consola_websocket \[ lindex \[.conexiones.lista get active\] 3 \]"
			
			frame .ultimo
			label .ultimo.lc -text "Consola web:"
			label .ultimo.c -textvar ::winix::configuracion(consola_web)
			label .ultimo.l -text "Ultimo Usuario conectado:"
			label .ultimo.u -textvar ::winix::uu

			pack .consola -side top -fill x -expand true
			pack .consola.t -side left
			pack .consola.e -side left -fill x -expand true
			pack .ultimo -side bottom -fill x -expand true
			pack .ultimo.lc .ultimo.u -side left
			pack .ultimo.c .ultimo.u -side left
			pack .ultimo.l .ultimo.u -side left
			pack .ok .lh -side bottom -fill x
			pack .estado -side left -fill y
			pack .sv -side left -fill y
			pack .conexiones -side left -fill both -expand true
			pack .conexiones.sbx -side bottom -fill x 
			pack .conexiones.lista -side left -fill both -expand true
			pack .conexiones.sb -side left -fill y 
			pack .entrada .salida .wsse .wsss -side top -fill y -expand true

#			pack .entrada.texto -fill y -side left -expand true
#			pack .entrada.sb -side left -fill y
#			pack .salida.texto -fill y -side left -expand true
#			pack .salida.sb -side left -fill y
#			pack .wsss.texto -fill y -side left -expand true
#			pack .wsss.sb -side left -fill y
#			pack .wsse.texto -fill y -side left -expand true
#			pack .wsse.sb -side left -fill y
			
			bind all <Control-k> {
				::winix::lista_variables
			}
			
			for { set l -4 } { $l <= [::winix::obtiene_valor nivel 5 ] } { incr l } {
				if [info exists ::debugcolorf($l)] {
				} else {
					set ::debugcolorf($l) $::debugcolorf(0)
					set ::debugcolorl($l) $::debugcolorl(0)
				}
				.estado tag configure tag$l \
					-background $::debugcolorf($l) \
					-foreground $::debugcolorl($l)
			}
		}
	}
	
	proc ::winix::consola_mensaje { mensaje { nivel 1 } { abrir no_cambio } { origen Maestro } } {
		if { "[::winix::obtiene_valor modalidad texto]" != "texto" } {
			if { $nivel <= [::winix::obtiene_valor nivel_consola 0] } {
				if [ catch {
					.estado insert end "\[$origen [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]\]-> $mensaje\n" tag$nivel
					switch $abrir {
						tronar {
							wm deiconify .
							grab .
							tkwait window .
							puts "Abrimos ventana grafica  por tronar"
							exit
						}
						abrir {
							puts "Abrimos ventana grafica  por abrir"
							wm deiconify .
						}
					}
				} resultado ] {
					::winix::asigna_valor nivel_consola 0 cargador "Deteccion del sistema grafico"
					puts "Problemas en el ambiente grafico de la consola [::winix::obtiene_valor nivel_consola 0]- $resultado - $::errorInfo"
				}
			} else {
			}
		} else {
			if { $nivel <= [::winix::obtiene_valor nivel_consola 0] } {
				puts "(Consola) \[$origen [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]\] $nivel -> $mensaje"
			}
		}
	}
	proc ::winix::consola_conexiones { } {
		if { "[::winix::obtiene_valor consola_web false]" == "true" } {
			.conexiones.lista delete 0 end
			foreach hilo [ lsort -dictionary [ ::tsv::array names usuarios ] ] {
				if { [::tsv::get programas $hilo programa] == 0} {
					set programa ""
				}
				if { [::tsv::get usuarios $hilo usuario] == 0} {
					set usuario ""
				}
				if { [::tsv::get dominios $hilo dominio] == 0} {
					set dominio ""
				}
				if { [::tsv::get ip $hilo ip] == 0} {
					set ip ""
				}
				if { [::tsv::get provisionado $hilo provisionado] == 0} {
					set provisionado ""
				}
				if {"$usuario" == "Eliminado"} {
					::tsv::set usuarios $hilo Eliminando
					::winix::eliminando_hilo_consola $hilo 2
				}
				if [::thread::exists $hilo ] { set status > } else { set status "" }
				.conexiones.lista insert end [ list $status $usuario $programa $hilo $dominio $ip $provisionado]
			}
			update
			after 1000 ::winix::consola_conexiones
		}
	}
	proc ::winix::eliminando_hilo_consola { hilo contador } {
		incr contador -1
		if {$contador > 0} {
			after 1000 ::winix::eliminando_hilo_consola $hilo $contador
		} else {
			catch { ::tsv::unset usuarios $hilo }
			catch { ::tsv::unset programas $hilo }
			catch { ::tsv::unset dominio $hilo }
			catch { ::tsv::unset ip $hilo }
		}
	}
	proc ::winix::manda_automata { hilo } {
		set ::folio 0

		set ::entrada_automata [ open automata/automata.$hilo.in r ]
		array set ::comandos [read $::entrada_automata [file size automata/automata.$hilo.in] ]
		close $::entrada_automata
		set ::folios [ lsort -integer [ array names ::comandos ] ]
		set ::total_folios [ llength $::folios ]

		toplevel .manda_automata
		label .manda_automata.folio -text ::folio
		label .manda_automata.primerfolio -text "Primer folio [lindex $::folios 0]"
		label .manda_automata.ultimofolio -text "Ultimo folio [lindex $::folios end]"
		label .manda_automata.hilo -text $hilo
		text .manda_automata.comando
		button .manda_automata.envia -text "Enviar comando automatico al hilo" -command {
			puts "Comandos:$::comandos([lindex $::folios $::folio])\\"
			::thread::send -async [.manda_automata.hilo cget -text ] [ list ::winix::navegador_directo $::comandos([lindex $::folios $::folio]) ]
			incr ::folio
			if { $::folio >= $::total_folios } {
				.manda_automata.envia configure -state disabled
			} else {
				.manda_automata.comando delete 0.0 end
				set ::paquete $::comandos([lindex $::folios $::folio])
				.manda_automata.comando insert end "$::paquete"
				.manda_automata.folio configure -text " Folio actual [lindex $::folios $::folio]  "
			}
		}
		button .manda_automata.enviamanual -text "Enviar comando manual al hilo" -command {
			::thread::send -async [.manda_automata.hilo cget -text ] [ list ::winix::navegador_directo [ .manda_automata.comando get 0.0 end] ]
		}
		pack .manda_automata.hilo
		pack .manda_automata.envia -side bottom
		pack .manda_automata.enviamanual -side bottom
		pack .manda_automata.comando -side bottom -expand yes -fill both
		pack .manda_automata.primerfolio -side left
		pack .manda_automata.folio -side left
		pack .manda_automata.ultimofolio -side left
		
		.manda_automata.comando delete 0.0 end
		set ::paquete $::comandos([lindex $::folios $::folio])
		.manda_automata.comando insert end "$::paquete"
		.manda_automata.folio configure -text [lindex $::folios 0]
	}
	proc ::winix::consola_salida { cadena {limpiar nada}} {
		if { "[::winix::obtiene_valor consola_web false]" == "true" } {
		
			if { "$limpiar" == "limpia" } {
				.salida.texto delete 0.0 end
			}
			.salida.texto insert end "$cadena\n"
		}
	}
	proc ::winix::consola_entrada { cadena {limpiar nada}} {
		if { "[::winix::obtiene_valor consola_web false]" == "true" } {
		
			if { "$limpiar" == "limpia" } {
				.entrada.texto delete 0.0 end
			}
			.entrada.texto insert end "$cadena\n"
		}
	}
	proc ::winix::consola_wss_salida { cadena {limpiar nada}} {
		if { "[::winix::obtiene_valor consola_web false]" == "true" } {
			if { "$limpiar" == "limpia" } {
				.wsss.texto delete 0.0 end
			}
			.wsss.texto insert end "$cadena\n"
		}
	}
	proc ::winix::consola_wss_entrada { cadena {limpiar nada}} {
		if { "[::winix::obtiene_valor consola_web false]" == "true" } {
			if { "$limpiar" == "limpia" } {
				.wsse.texto delete 0.0 end
			}
			.wsse.texto insert end "$cadena\n"
		}
	}

}

array set debugcolorf {
-4	yellow
-3	cyan
-2	red
-1	red
0	white
1	white
2	white
3	black
4	white
5	white
6	white
7	white
8	white
9	white
10	cyan
11	cyan
12	cyan
13	blue
14	cyan
15	cyan
16	cyan
}

array set debugcolorl {
-4	red
-3	white
-2	yellow
-1	white
0	black
1	red
2	green
3	yellow
4	orange
5	blue
6	gray
7	cyan
8	magenta
9	purple
10	black
11	red
12	green
13	yellow
14	orange
15	blue
16	gray
}
