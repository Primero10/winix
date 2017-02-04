package provide winix 3.0

namespace eval winix {
	proc ::winix::consola_mensaje { mensaje { nivel 1 } { abrir no_cambio} } {
		if { $nivel == -4 } {
			set compuesto "$mensaje\n"
			for {set level [ expr [info level] -1 ]} { $level > 0 } {incr level -1} {
				catch {
					append compuesto "\t$level [info level $level]\n"
					foreach { atributo valor } [info frame -[ expr [ info level ] - $level + 1] ] {
						append compuesto "\t\t$atributo -> $valor\n"
					}
				}
			}
			set mensaje $compuesto
		}

		set origen [ ::thread::id ]
		::thread::send -async [ ::tsv::get hilos consola ] [ concat ::winix::consola_mensaje [list $mensaje $nivel $abrir $origen ] ] 
	}
	proc ::winix::pool_sockets { sock ip port } {
		::thread::detach $sock
		::tpool::post [ ::tsv::get hilos pool_socks ] [ list ::winix::accept $sock $ip $port ]
	}
	proc ::winix::pool_hilos { sock ip port line } {
		::thread::detach $sock
		::winix::consola_mensaje "Transfiriendo socket a pool_web" 2
		::tpool::post [ ::tsv::get hilos pool_web ] [ subst {
			::winix::inicializar
			::winix::transfiere_socket $sock $ip $port "$line"
			set ::candado conectado
			vwait ::candado
		} ]
	}
	proc ::winix::consola_salida { cadena {limpiar nada} } {
		::thread::send -async [ ::tsv::get hilos consola ] [list ::winix::consola_salida "$cadena" $limpiar]
	}
	proc ::winix::consola_entrada { cadena {limpiar nada} } {
		::thread::send -async [ ::tsv::get hilos consola ] [list ::winix::consola_entrada "$cadena" $limpiar]
	}
	proc ::winix::consola_wss_salida { cadena {limpiar nada} } {
		::thread::send -async [ ::tsv::get hilos consola ] [list ::winix::consola_wss_salida "$cadena" $limpiar]
	}
	proc ::winix::consola_wss_entrada { cadena {limpiar nada} } {
		::thread::send -async [ ::tsv::get hilos consola ] [list ::winix::consola_wss_entrada "$cadena" $limpiar]
	}
}

