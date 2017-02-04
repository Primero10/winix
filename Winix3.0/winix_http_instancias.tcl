proc winfo { accion nombre args } {
	switch $accion {
		exists {
			if [info exist ::control_objetos($nombre) ] {
				return 1
			} else {
				return 0
			}
		}
	}
}

proc bind { args } { }

class tml {
	variable objeto
	variable proceso

	constructor { cuerpo_proceso } {
		set objeto	[lindex [split $this :] end]
		set proceso 	$cuerpo_proceso
	}

	destructor {
		debug "Clase tml: Me estoy muriendo... $this" 4
	}

	method ejecutar { { pagina ""} } {
		set siguiente_pagina $pagina
		
		::winix::consola_mensaje "Sustituyendo tml $this" 7
		set res "<head></head><body><h1>No existe tml con este nombre $this</h1></body>"
		if [ catch { set res [ subst $proceso ] } resultado ] {
			if { "[::winix::obtiene_valor debug False ]" == "true" } {
				set res "Error en la sustitucion de tml $pagina $resultado : $::errorInfo"
			}
			::winix::consola_mensaje "Error en la sustitucion de tml $pagina $resultado : $::errorInfo" 6
		}
		return $res
	}
}

namespace eval winix {
	variable objeto_consulta
	variable dormido [ clock seconds ]

	variable temporizador ""

	proc ::winix::inicializar { } {
		::tsv::set usuarios [::thread::id] ""
		if [ ::tsv::exists provisionado [::thread::id] ] {
		} else {
			::tsv::set provisionado [::thread::id] 0
		}
		::winix::asigna_programa ""
		if { "[ ::winix::obtiene_valor automata falso ]" == "Cierto" } {
			set ::automata [ open "automata/automata.[::thread::id].out" a ]
		}
		puts "[::thread::id] ->Hilo creado"
		set temporizador [ after 1000 ::winix::revisa_idle ]
	}

	proc ::winix::finalizar { } {
		::winix::consola_mensaje "Thread destruido para instancias [::thread::id]" 2

		::tsv::set usuarios [::thread::id] "Eliminado"
		::winix::asigna_programa ""
		puts "[::thread::id] ->Hilo destruido"
		after cancel $temporizador
		set temporizador ""
	}

	proc ::winix::termina_hilo { sock } {
		catch { close $sock }

		::winix::elimina_variables

		::tsv::set programas [ ::thread::id ] ""
		::tsv::set usuarios [ ::thread::id ] "___"
		::tsv::set dominios [ ::thread::id ] ""

		after 2000 [ subst { 
			::tsv::set usuarios [ ::thread::id ] ""
			::tsv::set programas [ ::thread::id ] ""
			::tsv::set dominios [ ::thread::id ] ""
			set ::candado desconectado 
		} ]
	}

	proc ::winix::revisa_idle { } {
		if { "$dormido" != "" } {
			set actual [ clock seconds ]
			if { [ expr $actual - $dormido ] > [ expr 60 * 60 ]} {
				::winix::navegador -comando Terminar
			}
		}
		set temporizador [ after 1000 ::winix::revisa_idle ]
	}

	proc ::winix::transfiere_socket { sock ip port line } {
		::winix::consola_mensaje "Comenzando transferencia de websocket" 1
		::thread::attach $sock

		::winix::elimina_variables
		catch { array unset ::control_objetos }
		catch { destroy object ::winix::objeto_consulta }

		::winix::asigna_valor master 		[::tsv::get hilos master ] 		threads tsv
		::winix::asigna_valor Server_Socket 	[::tsv::get entorno Server_Socket ] 	threads tsv
		::winix::asigna_valor debug 		[::tsv::get entorno debug ] 		threads tsv
		::winix::asigna_valor nivel 		[::tsv::get entorno nivel ] 		threads tsv

		set encabezados [ ::tsv::get $sock encabezados ]

		::winix::parse_encabezado $encabezados

		::winix::consola_mensaje "Asignando socket de servidor" 10
		::winix::websocket::server [::winix::obtiene_valor Server_Socket]
		::winix::consola_mensaje "Registrando call back" 10
		::winix::websocket::live [::winix::obtiene_valor Server_Socket] / ::winix::interfon
		::winix::consola_mensaje "Procesando encabezados" 10
		::winix::websocket::test [::winix::obtiene_valor Server_Socket] $sock $encabezados ::winix::interfon
		::winix::consola_mensaje "Regresando handshaking" 10
		::winix::websocket::upgrade $sock 
		::winix::asigna_valor websock $sock

		foreach { var val} [ ::tsv::array get $sock ] {
			::winix::asigna_valor $var $val Dominios "Transferencia socket"
		}

		foreach { var val} [ ::tsv::array get $sock ] {
			::winix::asigna_valor $var $val Dominios "Transferencia socket"
			::winix::consola_mensaje "$var -> $val"
		}

		set resultado ""
		if [ catch {
			consulta_web ::winix::objeto_consulta \
				-IP 		[::winix::obtiene_valor servidor_LAN 	] \
				-usuario 	[::winix::obtiene_valor web_usuario 	] \
				-clave 		[::winix::obtiene_valor web_clave 	] \
				-ssl 		[::winix::obtiene_valor ssl Falso 	] \
				-sslca 		[::winix::obtiene_valor sslca 		] \
				-sslcert 	[::winix::obtiene_valor sslcert 	] \
				-sslkey 	[::winix::obtiene_valor sslkey 		] \
				-persistente	Cierto \
				-Servidor	IP
			::winix::asigna_valor base_LAN [ ::winix::objeto_consulta obtiene_manejador ]
		} resultado ] {
			::winix::consola_mensaje "Error al crear objeto global de consultas $resultado : $::errorInfo " -1
		}

		if { "[ ::winix::ingresar web ]" == "" } {
			::winix::consola_mensaje "Error al conectar a la base de datos" 1
			set ::winix::paginas_integradas(index.html) "<h1>Servicio no fue configurado bien.</h1>"
			return 0
		}

		::tsv::set usuarios [::thread::id] [ ::winix::obtiene_valor web_usuario Error ]
		::tsv::incr provisionado [::thread::id]
		
		::winix::asigna_programa ""

		if { "[ ::winix::obtiene_valor automata falso ]" == "Cierto" } {
			set ::automata [ open "automata/automata.[::thread::id].out" a ]
		}

		::winix::arrancar
		
		::tsv::set hilos 	$sock 		 [ ::thread::id ]
		::tsv::set dominios 	[ ::thread::id ] [ ::winix::obtiene_valor web_dominio ]
		::tsv::set encabezados 	[ ::thread::id ] $encabezados
		::tsv::set ip 		[ ::thread::id ] "$ip:$port"

		::winix::asigna_valor websock $sock Dominios "Transferencia socket"
	}

	proc ::winix::interfon { websock type mensaje } {
		set PSA {
			;# Punto de Seguridad Auditoria PSA 
				Divorciar la generacion de HTML desde el codigo de clases)
				Divorciar el envio de referencias a objetos desde la pagina, deben indexarse por un arreglo de objetos
				Divorciar la ejecucion de metodos desde la pagina hacia el servidor, hacer inventario de peticiones de metodos validas
					y su equivalente como metodo interno.
		}
		::winix::consola_wss_entrada $mensaje limpia
		
		switch $type {
			close { 
				::winix::termina_hilo $websock
			}
			text {
				set dormido [ clock seconds ]
				if [ catch { set diccionario [::json::json2dict $mensaje] } resultado ] {
					::winix::consola_mensaje "Error al convertir json2dict: $::errorInfo" 14
				}

				set comando [dict get $diccionario comando]
				::winix::consola_mensaje "Comando: $comando se quiere ejecutar" 14
				
				switch $comando {
					CARGAR {
						set programa ""
						catch {
							set programa  [dict get $diccionario programa]
						}
						
						::winix::consola_mensaje "Parametros: programa = $programa" 14

						::winix::consola_mensaje "Ejecutando $programa" 14
						if [ catch {
							cargar $programa
						} resultado ] {
							::winix::consola_mensaje "Error al cargar programa $resultado" 14
						}
						return ""
					}
					BUSCA {
						set objeto  [dict get $diccionario objeto]
						set accion  [dict get $diccionario accion]

						::winix::consola_mensaje "Procesando $comando objeto $objeto con accion $accion" 14

						switch $accion {
							Actualiza {
								if [ catch {
									eval [list $::winix::objetos_datos($objeto) muestra ]
								} resultado ] {
									::winix::consola_mensaje "Error al procesar BUSCA $accion de objeto $objeto: $resultado - $::errorInfo" 14
								}
							}
							Enter {
								if [ catch {
									eval [list $::winix::objetos_datos($objeto) muestra Return ]
								} resultado ] {
									::winix::consola_mensaje "Error al procesar BUSCA $accion de objeto $objeto: $resultado - $::errorInfo" 14
								}
							}
							Aceptar {
								if [ catch {
									set padre	[dict get $diccionario padre]
									set programa	[dict get $diccionario programa]
									set renglon 	[dict get $diccionario renglon]
									set columna 	[dict get $diccionario columna]

									::winix::consola_mensaje "$::winix::objetos_busca($padre) procesa $objeto $renglon $columna" 14

									$::winix::objetos_busca($padre) procesa $objeto $renglon $columna
								} resultado ] {
									::winix::consola_mensaje "Error al procesar BUSCA $accion de busqueda $objeto: $resultado - $::errorInfo" 14
								}
							}
							Abrir {
								set objeto  [dict get $diccionario objeto]
								set destino  [dict get $diccionario destino]

								if [ catch {
									$destino limpia
									$objeto buscar 
								} resultado ] {
									::winix::consola_mensaje "Error al procesar BUSCA $accion de objeto $objeto: $resultado - $::errorInfo" 14
								}
							}
							Cuadricula {
								set objeto  [dict get $diccionario objeto]
								set destino  [dict get $diccionario destino]
								set renglon  [dict get $diccionario renglon]
								set columna  [dict get $diccionario columna]

								if [ catch {
									$::winix::objetos_cuadricula($objeto) buscar $renglon $columna
								} resultado ] {
									::winix::consola_mensaje "Error al procesar BUSCA $accion de objeto $objeto: $resultado - $::errorInfo" 14
								}
							}
							
						}
					}
					CUADRICULA {
						set objeto  [dict get $diccionario objeto]
						set accion  [dict get $diccionario accion]

						switch $accion {
							Aceptar {
								set objeto  		[dict get $diccionario objeto]
								set valor   		[dict get $diccionario valor]
								set renglon   		[dict get $diccionario renglon]
								set columna   		[dict get $diccionario columna]
								set valor_anterior 	""
								catch { set valoranterior [dict get $diccionario anterior] }
								if [ catch {
									eval [list $::winix::objetos_datos($objeto) ejecutar_evento Aceptar $valor $valor_anterior $renglon $columna ]
								} resultado ] {
									::winix::consola_mensaje "Error al procesar CUADRICULA $accion de objeto $objeto: $resultado - $::errorInfo" 1
								}
							}
							Registra {
								set objeto  [dict get $diccionario objeto]
								set valor   [dict get $diccionario valor]
								set renglon   [dict get $diccionario renglon]
								set columna   [dict get $diccionario columna]
								set valoranterior ""
								catch { set valoranterior   [dict get $diccionario anterior] }

								::winix::consola_mensaje "Procesando cuadricula registra para el objeto $objeto el valor $valor" 1

								set comando [list $::winix::objetos_datos($objeto) registra_valor_web $renglon $columna $valoranterior $valor ]

								if [ catch {
								eval $comando
								} resultado ] {
								::winix::consola_mensaje "Error al asignar valor $valor de objeto $objeto: $resultado - $::errorInfo" 1
								}
                                                        }
							RegistraBorrado {
								set objeto  [dict get $diccionario objeto]
								set registro   [dict get $diccionario registro]
								set renglon   [dict get $diccionario renglon]

								::winix::consola_mensaje "Procesando cuadricula registraborrado para el objeto $objeto el registro $registro" 1

								set comando [list $::winix::objetos_datos($objeto) registra_valor_borrado $renglon $registro ]

								if [ catch {
								eval $comando
								} resultado ] {
								::winix::consola_mensaje "Error al asignar registro $registro de objeto $objeto: $resultado - $::errorInfo" 1
								}
                                                        }
						}
					}
					
					Registra {
						set objeto  [dict get $diccionario objeto]
						set valor   [dict get $diccionario valor]
						
						::winix::consola_mensaje "Procesando evento para el objeto $objeto el valor $valor" 1
						
						set comando [list $::winix::objetos_datos($objeto) registra_valor_web $valor ]
						
						if [ catch {
							eval $comando
						} resultado ] {
							::winix::consola_mensaje "Error al asignar valor $valor de objeto $objeto: $resultado - $::errorInfo" 1
						}
					}
					EVENTO {
						set objeto  [dict get $diccionario objeto]
						set tipo    [dict get $diccionario tipo]
						set accion  [dict get $diccionario accion]

						::winix::consola_mensaje "Parametros: objeto = $objeto, tipo = $tipo, accion = $accion" 14

						debug "desglose del mensaje $tipo - $objeto - $accion"
						switch $tipo {
							boton {
								switch $accion {
									grabar 	{
										if [ catch {
											set comando [list $objeto grabar ]
											::winix::consola_mensaje "Procesando $comando" 14
											eval $comando
										} resultado ] {
											::winix::consola_mensaje "Error al procesar BOTON $accion de objeto $objeto: $resultado - $::errorInfo" 14
										}
									}
									borrar 	{
										if [ catch {
											eval [list $objeto borrar ]
										} resultado ] {
											::winix::consola_mensaje "Error al procesar BOTON $accion de objeto $objeto: $resultado - $::errorInfo" 14
										}
									}
									csv 	{
										if [ catch {
											eval [list $objeto generar_csv ]
										} resultado ] {
											::winix::consola_mensaje "Error al procesar BOTON $accion de objeto $objeto: $resultado - $::errorInfo" 14
										}
									}
									terminar {
										if [ catch {
											eval [list $objeto termina ]
										} resultado ] {
											::winix::consola_mensaje "Error al procesar BOTON $accion de objeto $objeto: $resultado - $::errorInfo" 14
										}
									}
									Ejecutar { 
										::winix::consola_mensaje "Procesando evento boton ejecutar, si paso por aqui $::winix::objetos_datos($objeto) " 14
										if [ catch {
											eval [list $::winix::objetos_datos($objeto) ejecutar_evento Ejecutar ]
										} resultado ] {
											::winix::consola_mensaje "Error al procesar BOTON $accion de objeto $objeto: $resultado - $::errorInfo" 14
										}
									}
								}
							}
							EVENTO {
								set valor  [dict get $diccionario valor]
								::winix::consola_mensaje "Procesando evento para el objeto $objeto el metodo $valor" 1
								if [ catch {
									eval [list $::winix::objetos_datos($objeto) ejecutar_evento <$valor> ]
								} resultado ] {
									::winix::consola_mensaje "Error al procesar EVENTO $accion de objeto $objeto: $resultado - $::errorInfo" 1
								}
							}
							ARBOL {
								switch $accion {
									ABRIR {
										set valor  [dict get $diccionario valor]
										::winix::consola_mensaje "Procesando evento para el objeto $objeto el metodo $valor" 1
										if [ catch {
											eval [list $::winix::objetos_datos($objeto) evalua_procesos Falso Abrir 0,0,0 $valor ]
										} resultado ] {
											::winix::consola_mensaje "Error al procesar ARBOL $accion de objeto $objeto: $resultado - $::errorInfo" 1
										}
									}
								}
							}
							RELACION {
								switch $accion {
									ABRIR {
										set valor  [dict get $diccionario valor]
										set detalle  [dict get $diccionario detalle]
										::winix::consola_mensaje "Procesando evento para el objeto $objeto el metodo $valor" 1
										if [ catch {
											eval [list $::winix::objetos_datos($objeto) evalua_procesos Falso Selecciona "$objeto,$valor,$detalle" $valor ]
										} resultado ] {
											::winix::consola_mensaje "Error al procesar RELACION $accion de objeto $objeto: $resultado - $::errorInfo" 1
										}
									}
								}
							}
							LISTA {
								switch $accion {
									ABRIR {
										set valor  [dict get $diccionario valor]
										set detalle  [dict get $diccionario detalle]
										::winix::consola_mensaje "Procesando evento para el objeto $objeto el metodo $valor" 1
										if [ catch {
											eval [list $::winix::objetos_datos($objeto) evalua_procesos Falso Selecciona "$objeto,$valor,$detalle" $valor ]
										} resultado ] {
											::winix::consola_mensaje "Error al procesar LISTA $accion de objeto $objeto: $resultado - $::errorInfo" 1
										}
									}
								}
							}
							AYUDA {
								switch $accion {
									EDITOR 	{
										if [ catch {
											eval [list ::winix::edita_ayuda $objeto ]
										} resultado ] {
											::winix::consola_mensaje "Error al procesar CARGAR $accion de objeto $objeto: $resultado - $::errorInfo" 14
										}
									}
									MOSTRAR	{
										if [ catch {
											eval [list ::winix::consulta_ayuda $objeto ]
										} resultado ] {
											::winix::consola_mensaje "Error al procesar CARGAR $accion de objeto $objeto: $resultado - $::errorInfo" 14
										}
									}
									CARGAR	{
										set valor  [dict get $diccionario valor]
										if [ catch {
											eval [list $::winix::objetos_datos($objeto) evalua_procesos Falso Liga $valor ]
										} resultado ] {
											::winix::consola_mensaje "Error al procesar CARGAR $accion de objeto $objeto: $resultado - $::errorInfo" 14
										}
									}
								}
							}
 						}
						return ""
					}
					FOCO {
						set objeto  [dict get $diccionario objeto]
						set tipo    [dict get $diccionario tipo]
						set detalle    [dict get $diccionario detalle]

						::winix::consola_mensaje "Procesando FOCO para el objeto $objeto el tipo $tipo" 1

						switch $tipo {
							pestana {
								if [ catch {
									eval [list $::winix::objetos_datos($objeto) foco $detalle ]
								} resultado ] {
									::winix::consola_mensaje "Error al procesar evento foco de objeto $objeto: $resultado - $::errorInfo" 1
								}
							}
							dato {
								if [ catch {
									eval [list $::winix::objetos_datos($objeto) foco_directo ]
								} resultado ] {
									::winix::consola_mensaje "Error al procesar evento foco de objeto $objeto: $resultado - $::errorInfo" 1
								}
							}
						}
					}
					LIGA {
						set programa  [dict get $diccionario programa]
						set destino ""
						catch {
							set destino   [dict get $diccionario destino]
						}
						if { "$destino" == "" } { set destino "main" }
						set parametros ""
						catch {
							set parametros   [dict get $diccionario parametros]
						}
						set websocket $websock
						::winix::portal_carga_script $programa $websocket $destino $parametros
					}
					CERRAR {
						set objeto  [dict get $diccionario objeto]

						if [ catch {
							eval [list $::winix::objetos_datos($objeto) termina Ciego ]
						} resultado ] {
							::winix::consola_mensaje "Error al procesar evento foco de objeto $objeto: $resultado - $::errorInfo" 1
						}
					}
					TERMNAR {
						::winix::termina_hilo $websock
					}
				}
			}
			1001 {
				::winix::termina_hilo $websock
			}
		}
	}

	proc ::winix::navegador { args } {
		if [info exists ::automata] {
			incr ::folio
			puts $::automata [list $::folio $args]
			flush $::automata
		}
		set websock [::winix::obtiene_valor websock ""]
		if {"$websock" == ""} {
			::winix::consola_mensaje "Tengo perdido mi websocket [::winix::obtiene_valor thread] $args" 2
			::winix::consola_mensaje "Soy el hilo [::winix::obtiene_valor thread] y no lo encuentro" 2
			return
		}

		yajl create pre_json -beautify 1
		pre_json map_open
		foreach {opcion dato} $args {
			set contenedor [string range $opcion 1 end]
#			set dato [subst -novariables [regsub -all {[][\u0000-\u001f\\""]} $valor {[format "\\\\u%04x" [scan {& } %c]]}]]
			set magic_number [ string range $dato 0 1]
			switch $magic_number {
				"#1"	{
						pre_json string $contenedor array_open
						foreach valor [string range $dato 2 end] {
							set dato_formateado [subst -novariables [regsub -all {[][\u0000-\u001f\\""]} $valor {[format "\\\\u%04x" [scan {& } %c]]}]]
							pre_json string $dato_formateado
						}
						pre_json array_close
					}
				"#2"	{
						pre_json string $contenedor map_open string data array_open
						foreach lista [string range $dato 2 end] {
							pre_json array_open
							foreach valor $lista {
								set dato_formateado [subst -novariables [regsub -all {[][\u0000-\u001f\\""]} $valor {[format "\\\\u%04x" [scan {& } %c]]}]]
								pre_json string $dato_formateado
							}
							pre_json array_close
						}
						pre_json array_close map_close
					}
				default {
					pre_json string $contenedor string $dato
				}
			}
			set nivel 10
			if { "$opcion" == "-comando" } {
				if [ info exists ::debug_nivel($dato)] {
					set nivel $::debug_nivel($dato)
				} else {
					set nivel 22
				}
			}
		}
		pre_json map_close
		set json [pre_json get ]
		::winix::consola_mensaje "Navegador $args -> \n$json" $nivel
		::winix::websocket::send $websock text $json
		::winix::consola_wss_salida "$args" limpia
	}
	
	proc ::winix::navegador_directo { args } {
		puts $args

		set websock [::winix::obtiene_valor websock ""]
		if {"$websock" == ""} {
			return
		}

		yajl create pre_json -beautify 1
		pre_json map_open
		foreach {opcion dato} [lindex $args 0] {
			set contenedor [string range $opcion 1 end]
#			set dato [subst -novariables [regsub -all {[][\u0000-\u001f\\""]} $valor {[format "\\\\u%04x" [scan {& } %c]]}]]
			set magic_number [ string range $dato 0 1]
			switch $magic_number {
				"#1"	{
						pre_json string $contenedor array_open
						foreach valor [string range $dato 2 end] {
							set dato_formateado [subst -novariables [regsub -all {[][\u0000-\u001f\\""]} $valor {[format "\\\\u%04x" [scan {& } %c]]}]]
							pre_json string $dato_formateado
						}
						pre_json array_close
					}
				"#2"	{
						pre_json string $contenedor map_open string data array_open
						foreach lista [string range $dato 2 end] {
							pre_json array_open
							foreach valor $lista {
								set dato_formateado [subst -novariables [regsub -all {[][\u0000-\u001f\\""]} $valor {[format "\\\\u%04x" [scan {& } %c]]}]]
								pre_json string $dato_formateado
							}
							pre_json array_close
						}
						pre_json array_close map_close
					}
				default {
					pre_json string $contenedor string $dato
				}
			}
		}
		pre_json map_close
		set json [pre_json get ]
		::winix::websocket::send $websock text $json
	}

	proc ::winix::asigna_programa { programa { hilo "" } } {
		::tsv::set programas [ ::thread::id ] $programa
	}

	proc ::winix::limpia_encabezados {} {
		array set ::winix::html_elementos {
			Get				""
			Host				""
			User-Agent			""
			Accept				""
			Accept-Language			""
			Accept-Encoding			""
			Connection			""
			Referer				""
			Content-Type			""
			Content-Length			""
			Cookie				""
			Cache-Control			""
			Origin				""
			Pragma				""
			Upgrade				""
			Sec-WebSocket-Version		""
			Sec-WebSocket-Key		""
			Sec-WebSocket-Extensions	""
			Sec-WebSocket-Protocol		""
		}
	}
	proc ::winix::formato_fecha {seconds} {
		return [clock format $seconds -format {%a, %d %b %Y %T %Z}]
	}
	proc ::winix::parse_encabezado { encabezados } {
		catch { array unset ::winix::html_elementos }

		foreach { codigo valor} $encabezados {
			set ::winix::html_elementos($codigo) $valor
		}
	}

	proc ::winix::enviar { sock cadena } {
		::winix::consola_salida "$cadena"
		puts $sock $cadena
	}
}

proc avance { mensaje_avance { magnitud 0 } } {
	::winix::consola_mensaje "$magnitud > $mensaje_avance" 10
	::winix::navegador -comando AVANCE -subcomando ASIGNA -letrero $mensaje_avance -valor $magnitud

}