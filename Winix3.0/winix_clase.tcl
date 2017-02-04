package provide winix 3.0

namespace eval winix {
	proc ::winix::trace_variable { var modo } {
		if [info exist ::winix::traces(tracer_activo)] {
		} else {
			trace add variable ::winix::configuracion 	read  "::winix::tracer"
			trace add variable ::winix::configuracion 	write "::winix::tracer"
			trace add variable ::conf 			read  "::winix::tracer"
			trace add variable ::conf 			write "::winix::tracer"
			trace add variable ::winix::configuracion 	array "::winix::tracer"
			trace add variable ::conf 			array "::winix::tracer"

		}
		set ::winix::traces($var) $modo
		set ::winix::traces(tracer_activo) ""
	}
	proc ::winix::tracer { var indice operacion } {
		if [ info exists ::winix::traces($indice)] {
			puts "=======================================================$var $indice $operacion"
			for {set level [ expr [info level] -1 ]} { $level > 0 } {incr level -1} {
				catch {
					puts "\t$level [string range [info level $level] 0 100]\n"
				}
			}
			puts "======================================================="
		}
		if { "$operacion" == "array" } {
			puts ">>>> $var $indice $operacion"
		}
	}
	proc ::winix::elimina_variables { } {
		array unset ::winix::configuracion
		array unset ::winix::origenes
		array unset ::winix::tipos
	}
	proc ::winix::asigna_valor { var valor { origen sistema} { tipo codigo } } {
		set ::winix::configuracion($var) $valor
		set ::winix::origenes($var) $origen
		set ::winix::tipos($var) $tipo
		if [info exists ::winix::configuracion(compatible_2)] {
			if {"$::winix::configuracion(compatible_2)" == "Cierto" } {
				set ::conf($var) $valor
			}
		} else {
			set ::winix::configuracion(compatible_2) Falso
		}
	}

	proc ::winix::obtiene_valor { var { default "" } } {
		if [info exists ::winix::configuracion($var)] {
			return $::winix::configuracion($var)
		} else {
			set ::winix::configuracion($var) $default
			set ::winix::origenes($var) codigo
			set ::winix::tipos($var) default
			if [info exists ::winix::configuracion(compatible_2)] {
				if {"$::winix::configuracion(compatible_2)" == "Cierto" } {
					set ::conf($var) $default
				}
			} else {
				set ::winix::configuracion(compatible_2) Falso
			}
			return $default
		}
	}
	
	proc ::winix::variable_local { var { default "" } } {
		debug "Comando descontinuado, cambie la llamada por ::winix::obtiene_valor " -1
		return [ ::winix::obtiene_valor $var $default ]
	}

	proc ::winix::elimina_variables_web { } {
		array unset ::winix::web_configuracion
		array unset ::winix::web_origenes
		array unset ::winix::web_tipos
	}

	proc ::winix::asigna_valor_web { var valor { origen sistema} { tipo codigo } } {
		set ::winix::web_configuracion($var) $valor
		set ::winix::web_origenes($var) $origen
		set ::winix::web_tipos($var) $tipo
	}

	proc ::winix::obtiene_valor_web { var { default "" } } {
		if [info exists ::winix::web_configuracion($var)] {
			return $::winix::web_configuracion($var)
		} else {
			set ::winix::web_configuracion($var) $default
			set ::winix::web_origenes($var) codigo
			set ::winix::web_tipos($var) default
			return $default
		}
	}

	proc ::winix::lista_variables { } {
		foreach var [lsort [array names ::winix::configuracion]] {
			if { "[::winix::obtiene_valor modo_web falso]" == "Cierto"} {
				::winix::consola_mensaje "$var = \"$::winix::configuracion($var)\" $::winix::origenes($var) $::winix::tipos($var)" 10
			} else {
				debug "$var = \"$::winix::configuracion($var)\" $::winix::origenes($var) $::winix::tipos($var)" 1
			}
		}
	}
	proc ::winix::obtiene_instancias_web { } {
		set plataforma [::winix::obtiene_valor plataforma ]
		puts "Plataforma es $plataforma"
		if { "$plataforma" == "witc" } {
			set conexiones ""
			set resultado ""
			set hilos [ lsort -dictionary [ ::tsv::array names usuarios ] ]
			foreach hilo $hilos {
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
					catch { ::tsv::unset usuarios $hilo }
					catch { ::tsv::unset programas $hilo }
					catch { ::tsv::unset dominio $hilo }
					catch { ::tsv::unset ip $hilo }
				} else {
					if [::thread::exists $hilo ] { 
						set status > 
					} else { 
						set status "" 
						::tsv::set usuarios $hilo Eliminado
					}
					lappend conexiones [ list $status $hilo $usuario $dominio $programa $ip $provisionado]
				}
			}
			return $conexiones
		} else {
			debug "La plataforma es: [::winix::obtiene_valor plataforma ] por eso no puedo consultar instancias"
			return ""
		}
	}
	proc ::winix::obtiene_niveles { instancia { default Consulta } } {
		if [info exists ::winix::niveles($instancia)] {
			return $::winix::niveles($instancia)
		} else {
			set ::winix::niveles($instancia) $default
			set ::winix::niveles_asignacion($instancia) codigo
			return $default
		}
	}
	proc ::winix::asigna_nivel { instancia valor } {
		set ::winix::niveles($instancia)] $valor
	}
	proc ::winix::existe_variable { var } {
		if [info exists ::winix::configuracion($var)] {
			return 1
		} else {
			return 0
		}
	}
	proc ::winix::existe_archivo_configuracion { var } {
		if [info exists ::winix::configuracion($var)] {
			if [ file exists $::winix::configuracion($var) ] {
				return 1
			} else {
				return 0
			}
		} else {
			return 0
		}
	}
	proc ::winix::report_trace args {
		#puts [info level 0]
	}
	proc ::winix::tcl2json value {
		# Guess the type of the value; deep *UNSUPPORTED* magic!
		regexp {^value is a (.*?) with a refcount} [::tcl::unsupported::representation $value] -> type

		switch $type {
			string {
				# Skip to the mapping code at the bottom
			}
			dict {
				set result "{"
				set pfx ""
				dict for {k v} $value {
					append result $pfx [tcl2json $k] ": " [tcl2json $v]
					set pfx ", "
				}
				return [append result "}"]
			}
			list {
				set result "\["
				set pfx ""
				foreach v $value {
					append result $pfx [tcl2json $v]
					set pfx ", "
				}
				return [append result "\]"]
			}
			int - double {
				return [expr {$value}]
			}
			booleanString {
				return [expr {$value ? "true" : "false"}]
			}
			default {
				# Some other type; do some guessing...
				if {$value eq "null"} {
					# Tcl has *no* null value at all; empty strings are semantically
					# different and absent variables aren't values. So cheat!
					return $value
				} elseif {[string is integer -strict $value]} {
					return [expr {$value}]
				} elseif {[string is double -strict $value]} {
					return [expr {$value}]
				} elseif {[string is boolean -strict $value]} {
					return [expr {$value ? "true" : "false"}]
				}
			}
		}
		
		# For simplicity, all "bad" characters are mapped to \u... substitutions
#		set mapped [subst -novariables [regsub -all {[][\u0000-\u001f\\""]} $value {[format "\\\\u%04x" [scan {& } %c]]}]]
		set mapped $value
		return "\"$mapped\""
	}
}

array set debugcolorf {
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
	-2	yellow
	-1	black
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
