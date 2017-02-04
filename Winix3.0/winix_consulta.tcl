#proc mensaje_log { args } {
#}
#
#proc problemas { args } {
#}
#
#proc debug { args } {
#}
#
class consulta_web {
	variable cadena_original
	variable cadena_complemento
	variable procesos
	variable registros
	variable total_registros
	variable total_campos
	variable nombres_campos
	variable cursor
	variable nombres
	variable iniciales
	variable objetos
	variable ip
	variable usuario
	variable clave
	variable manejador
	variable ssl
	variable sslca
	variable sslkey
	variable sslcert
	variable persistente
	variable tablas 
	variable tablas_sincronizacion 
	variable varID_llaveinsertada
	variable arreglo_basedatos
	variable servidor
	variable bd_datos
	variable bd_winix
	variable bd_sistema

	constructor { args } {
		set cadena ""
		set cadena_complemento ""
		set procesos(0) "vacia"
		set registros ""
		set total_registros -1
		set total_campos -1
		set cursor -1
		set nombres_campos ""
		set ip ""
		set usuario ""
		set clave ""
		set ssl ""
		set sslca ""
		set sslkey ""
		set sslcert ""
		set persistente "Falso"
		set manejador ""
		set servidor Normal
		set bd_datos ""
		set bd_winix ""
		set bd_sistema ""

		foreach {opcion valor} $args {
			switch -- $opcion {
				-Sentencia {
					set cadena_original $valor
				}
				-Complemento {
					set cadena_complemento $valor
				}
				-Procesos {
					set ind 0
					foreach { pro tip obj } $valor {
						set procesos($ind)		$pro
						set tipos_procesos($ind)	$tip
						set objetos($ind)		$obj
						debug "Dando de alta proceso en campo $this, proceso ( $pro ) tipo ($tip) objetos ( $obj )" 5
						incr ind
					}
				}
				-Variables {
					set ind 0
					foreach { nombre inicial objeto } $valor {
						set nombres($ind)   $nombre
						set iniciales($ind) $inicial
						set objetos($ind)   $objeto
						incr ind
						debug "Cargando parametro -Variables de clase consulta nombre:($nombre) valor inicial:($inicial) objeto: ($objeto)" 13
					}
				}
				-IP {
					set ip $valor
				}
				-Servidor {
					set servidor $valor
				}
				-usuario {
					set usuario $valor
				}
				-clave {
					set clave $valor
				}
				-ssl {
					set ssl $valor
				}
				-sslca {
					set sslca $valor
				}
				-sslkey {
					set sslkey $valor
				}
				-sslcert {
					set sslcert $valor
				}
				-persistente {
					set persistente $valor
				}
				-bd {
					set bd_datos $valor
				}
				-bd_sistema {
					set bd_sistema $valor
				}
				-bd_winix {
					set bd_winix $valor
				}
				default {
					debug "Error en consulta: opcion desconocida en objeto $this ( $opcion = $valor )" -1
				}
			}

		}

		abrir_manejador

		cargar_tablas_sincronizacion
	}

	destructor {
		debug "Me estoy muriendo... $this" 4

		if [ catch { mysqlclose $manejador } resultado ] {
			::winix::consola_mensaje "Error para cerrar manejador $manejador - $resultado" -1
		}
	}

	method ejecutar { { compatible se_ignora } { modalidad Sustituye_Hibrido } { tipo_consulta Consulta}} {
		set cadena $cadena_original
		set consultadas ""

		::winix::consola_mensaje "Mandaron llamar a $this -> ejecutar con las opciones $servidor $modalidad $tipo_consulta" 3
		::winix::consola_mensaje "Las propiedades son: ip          = $ip" 3
		::winix::consola_mensaje "                     persistente = $persistente" 3
		::winix::consola_mensaje "                     usuario     = $usuario" 3
		::winix::consola_mensaje "                     manejador   = $manejador" 3
		::winix::consola_mensaje "======================================================================" 3
		::winix::consola_mensaje "$cadena" 3
		::winix::consola_mensaje "======================================================================" 3

		switch -- $modalidad {
			Directo {
			}
			Sustituye_Iniciales {
				set mascara ""
				foreach {ind} [lsort [array names nombres ]] {
					set valores($ind) $iniciales($ind)
					lappend mascara "<:$nombres($ind):>" $valores($ind)
				}
				debug "Sustituyendo valores  en cadena sql Mascara($mascara) cadena ($cadena)" 23
				set cadena [string map $mascara $cadena]
			}
			Sustituye_Objetos {
				set mascara ""
				foreach {ind} [lsort [array names nombres ]] {
					if {"$objetos($ind)" != ""} {
						set valores($ind) [$objetos($ind) obtiene_valor]
					} else {
						set valores($ind) ""
					}
					lappend mascara "<:$nombres($ind):>" $valores($ind)
				}
				debug "Sustituyendo valores  en cadena sql Mascara($mascara) cadena ($cadena)" 23
				set cadena [string map $mascara $cadena]
			}
			Sustituye_Hibrido {
				set mascara ""
				foreach {ind} [lsort [array names nombres ]] {
					debug "Nombre de objeto a cambiar $nombres($ind) que es el indice $ind" 23
					if {"$objetos($ind)" != ""} {
						set valores($ind) [$objetos($ind) obtiene_valor]
					} else {
						set valores($ind) $iniciales($ind)
					}
					lappend mascara "<:$nombres($ind):>" $valores($ind)
				}
				debug "Sustituyendo valores  en cadena sql Mascara($mascara) cadena ($cadena)" 23
				set cadena [string map $mascara $cadena]
			}
			Sustituye_Vacios {
				set mascara ""
				foreach {ind} [lsort [array names nombres ]] {
					debug "Nombre de objeto a cambiar $nombres($ind) que es el indice $ind" 23
					if {"$objetos($ind)" != ""} {
						set valores($ind) [$objetos($ind) obtiene_valor]
						if {"$valores($ind)" == ""} {
							set valores($ind) $iniciales($ind)
						}
					} else {
						set valores($ind) $iniciales($ind)
					}
					lappend mascara "<:$nombres($ind):>" $valores($ind)
				}
				debug "Sustituyendo valores  en cadena sql Mascara($mascara) cadena ($cadena)" 23
				set cadena [string map $mascara $cadena]
			}
		}

		set pos 0
		set final -1
		set inicio -1
		for { } { 1 } { } {
			set inicio [string first "<*" $cadena $pos ]
			if { $inicio == -1 } break
			set final [string first "*>" $cadena $inicio ]
			if { $final == -1 } break
			incr final
			set tabla [string range $cadena [expr $inicio + 2 ] [expr $final - 2 ] ]
			set bd [ base_datos $tabla]
			set completo "$bd.$tabla"
			set cadena [string replace $cadena $inicio $final $completo]
			set pos [expr $final + 1]
			lappend consultadas " $completo"
		}

		debug "Cadena con tablas sustituidas $cadena" 23

		set pos 0
		for { } { 1 } { } {
			set inicio [string first "<_" $cadena $pos ]
			if { $inicio == -1 } break
			set final [string first "_>" $cadena $inicio ]
			if { $final == -1 } break
			incr final
			set campo [string range $cadena [expr $inicio + 2 ] [expr $final - 2 ] ]
			set valor ""
			if [ catch { set valor [::winix::obtiene_valor $campo] } resultado ] {
				::winix::consola_mensaje "Error al convertir variable de entorno $resultado" -4
			}
			set cadena [string replace $cadena $inicio $final $valor]
			set pos [expr $final + 1 ]
		}

		set cadena "$cadena $cadena_complemento"

		debug "Ejecutando servidor $servidor con modalidad $tipo_consulta persistencia $persistente - $manejador - $cadena" 5
		if {"$tipo_consulta" == "Consulta"} {
			set control_sql [ sql $cadena ]

		} else {
			set control_sql [ sql $cadena \
				-Modalidad Ejecutar \
			]

			set control_sql ""
			set registros 0
			set nombres_campos ""
			set total_registros 0
			set total_campos 0
			return 0
		}

		set registros [lindex $control_sql 0]
		set nombres_campos [lindex $control_sql 1]
		set total_registros [lindex $control_sql 2]
		set total_campos [lindex $control_sql 3]

		if { "$total_registros" == "0" } {
			::winix::consola_mensaje "-------------Datos de la consulta-------------------" -1
			::winix::consola_mensaje "Registros     : $total_registros" -1
			::winix::consola_mensaje "Campos        : $total_campos" -1
			::winix::consola_mensaje "Nombres Campos: $nombres_campos" -1
			::winix::consola_mensaje "Informacio de registros: $registros" -1
			::winix::consola_mensaje "Tablas consultadas     : $consultadas" -1
			::winix::consola_mensaje "bd                     : $bd_datos" -1
			::winix::consola_mensaje "bd_sistema             : $bd_sistema" -1
			::winix::consola_mensaje "bd_winix               : $bd_winix" -1
			::winix::consola_mensaje "objeto                 : $this" -1
			::winix::consola_mensaje "$cadena" -1
		} else {
			::winix::consola_mensaje "-------------Datos de la consulta-------------------" 22
			::winix::consola_mensaje "Registros     : $total_registros" 22
			::winix::consola_mensaje "Campos        : $total_campos" 22
			::winix::consola_mensaje "Nombres Campos: $nombres_campos" 22
			::winix::consola_mensaje "Informacio de registros: $registros" 22
		}

		return 0
	}

	method asigna_sentencia { nueva_sentencia { nuevo_complemento "" } } {
		set cadena_original $nueva_sentencia
		set cadena_complemento $nuevo_complemento
	}

	method asigna_variables { valor } {
		array unset nombres
		array unset iniciales
		array unset objetos
		set ind 0
		foreach { nombre inicial objeto } $valor {
			set nombres($ind)   $nombre
			set iniciales($ind) $inicial
			set objetos($ind)   $objeto
			incr ind
			debug "Cargando variables por metodo de objeto consulta nombre:($nombre) valor inicial:($inicial) objeto: ($objeto)" 13
		}
	}

	method consulta_express { query {estilo_lista ""} } {
		asigna_sentencia $query

		ejecutar Normal Sustituye_Vacios Consulta

		set reg [ obtiene_registros ]

		if { "$estilo_lista" == "flatlist" } {
			set ret ""
			foreach lin $reg {
				foreach dat $lin {
					lappend ret $dat
				}
			}
			return $ret
		} else {
			return $reg
		}
	}

	method cambia_usuario { args } {

		if { "$persistente" == "Cierto" && "$servidor" == "IP"} {
			catch { mysqlclose $manejador }
			set manejador ""
			::winix::consola_mensaje "[::thread::id] -> $manejador <- cambio_usuario" 20
		}

		foreach {par val} $args {
			switch -- $par {
				-usuario {
					set usuario $val
				}
				-clave {
					set clave $val
				}
			}
		}

		if { "$persistente" == "Cierto" && "$servidor" == "IP"} {
			set persistente Falso
			abrir_manejador
			set persistente Cierto
			cargar_tablas_sincronizacion
		}
	}

	method obtiene_registros { } {
		return $registros
	}

	method obtiene_total_campos { } {
		return $total_campos
	}

	method obtiene_total_registros { } {
		return $total_registros
	}

	method obtiene_posicion_actual { } {
		return $cursor
	}

	method obtiene_nombres_campos { } {
		return $nombres_campos
	}

	method obtiene_manejador { } {
		return $manejador 
	}

	method cargar_tablas_sincronizacion {} {
		catch { array unset tablas_sincronizacion }
		catch { array unset arreglo_basedatos }

		set cadena_sql "
			SELECT Tabla, MetodoSincronia, BaseDatos
			FROM [ ::winix::obtiene_valor_web db].tablas
		"
		
		abrir_manejador

		if { [catch {mysqlsel $manejador $cadena_sql -flatlist} resultado]} { 
			mensaje_log "LOCAL: $resultado [ ::winix::obtiene_valor_web db] tablas"
			problemas "Error 11: No se pudo cargar configuracion de Sincronia, con la sentencia $cadena_sql
				manejador $manejador servidor $servidor ip $ip
			" $resultado
		}	

		foreach { nombre_tabla metodo_sincronia base_datos } $resultado {
			debug "La tabla $nombre_tabla se sincroniza $metodo_sincronia en la base de datos $base_datos" 21
			set tablas_sincronizacion($nombre_tabla) $metodo_sincronia
			if { "$base_datos" != "" } {
				set arreglo_basedatos($nombre_tabla) $base_datos
			}
		}

		cerrar_manejador Termino
	}

	method consulta_sql { cadena {tipo -list}} {
    		# Se encuentra la información de cada tabla que voy encontrando en la cadena
    		# ya sea local, sincronizar, etc.
    		set info_tablas ""
    
    		# Inicializa variables que se usaran al armar la cadena de sql
    		set var_select ""
    		set var_from   ""
    		set var_left   ""    
    		set var_where  ""
    		set var_group  ""
		set var_having ""
    		set var_order  ""
    
    		foreach {llave valor} $cadena {
       			set llave [string toupper $llave]
        		switch -- $llave {
            			-SELECT { set var_select "SELECT [cargar_campos_dato $valor 1]" }
            			-FROM   {                
                			set inf [revisa_metodos_tablas $valor $info_tablas]
                			set info_tablas [lindex $inf 0]
							set tab [lindex $inf 1]
                			set var_from   "FROM $tab"
            			}
            			-LEFT   {
                			set var_join ""
                			set var_on   ""
                			foreach {opc val} $valor {
                    				set opc [string toupper $opc]
                    				switch -- $opc {
                        				-JOIN {
                            					set inf [revisa_metodos_tablas $val $info_tablas]
                            					set info_tablas [lindex $inf 0]
												set tab [lindex $inf 1]
                            					set var_join "LEFT JOIN $tab"
                        				}
                        				-ON {                            
                            					set var_on "ON [cargar_campos_dato $val 2]"
                        				}
                    				}                    
                			}
                
                			append var_left "$var_join $var_on " 
           		 	}
            			-WHERE  { set var_where "WHERE [cargar_campos_dato $valor 2]"   }
            			-GROUPBY { set var_group "GROUP BY [cargar_campos_dato $valor 2]"}
			-HAVING {set var_having "HAVING [cargar_campos_dato $valor 2]"}
           			-ORDERBY { set var_order "ORDER BY [cargar_campos_dato $valor 2]"}
        		}
		}        
    
		set sql "
			$var_select
			$var_from
			$var_left
			$var_where
			$var_group
			$var_having
			$var_order
		"
        
		debug "Cadena SQL que se ejecutara: $sql" 5

		abrir_manejador

		if [ catch {
			set res [mysqlsel $manejador $sql $tipo] 
		} resultado ] {
			::bitacora::mensaje "LOCAL: $resultado $sql"
			problemas "Sucedio un problema con la conexion a la base de datos, con la sentencia $sql " $resultado
			return
		}
        
		cerrar_manejador Termino

    		return $res
	}

	# Busca en la cadena si existen objetos de la clase DATO, y carga sus campos y valores
	# Existen 2 niveles:
	#    1 - Sustituye el objeto por el nombre del campo solamente  (campo)
	#    2 - Sustituye el objeto por el nombre del campo y su valor (campo=valor)
	method cargar_campos_dato {cadena nivel} {
    		foreach {pos} [lsearch -regexp -all $cadena {^::}] {        
        		set objeto [lindex $cadena $pos]    
        		set campo [$objeto obtiene_nombre]
        		set valor [$objeto obtiene_valor]
			debug "$objeto, $campo, $valor" 10
        		switch -- $nivel {
            			1 {
                			set cadena [lreplace $cadena $pos $pos "$campo"]
            			}
            			2 {
                			set cadena [lreplace $cadena $pos $pos "$campo='[mysqlescape $valor]'"]
            			}
        		}
    		}
    
    		return $cadena
	}

	method revisa_metodos_tablas { tbls info_tablas } {
		variable tablas
    
    		# Primero quito las comas a las tablas  y luego les quito
    		# el alias, en caso de que lo tenga

    		set lista ""
    		foreach {tab} [split $tbls ,] {        
			set nm_tabla [string trim [lindex $tab 0]]
			set nm_tabla [string trim [lindex [split $nm_tabla .] end]]
        
        
			if {[info exists tablas_sincronizacion($nm_tabla)]} {
			} else {
				set tablas_sincronizacion($nm_tabla) local
			}
        
			set basedatos [base_datos $nm_tabla]
        
        		if {$nm_tabla eq "act"} {
            			lappend lista "$basedatos.$nm_tabla [string trim [lrange $tab 1 end]]"
            			lappend info_tablas $basedatos.$nm_tabla metodo
        		} else  {
            			lappend lista "$basedatos.$nm_tabla [string trim [lrange $tab 1 end]]"
            			lappend info_tablas $basedatos.$nm_tabla local
        		}
    		}
    
    		return [list $info_tablas [join $lista ,]]
	}

	method hora { } {
		abrir_manejador

		set res ""

		if [ catch { 
			set res [ lindex [lindex [mysqlsel $manejador "select now()" -flatlist] 0 ] 1 ] 
		} resultado ] {
			::winix::consola_mensaje "Error para obtener la hora $resultado" -4
		}

		cerrar_manejador

		return $res
	}

	method fecha { } {
		abrir_manejador

		set res ""

		if [ catch { 
			set res [ lindex [mysqlsel $manejador "select curdate()" -flatlist] 0 ] 
		} resultado ] {
			::winix::consola_mensaje "Error para obtener la fecha $resultado" -4
		}

		cerrar_manejador

		return $res
	}

	method escapa_caracteres { cadena } {
		return [mysqlescape $cadena]
	}
	
	method cerrar_manejador { { tipo normal } } {
		if { "$persistente" != "Cierto" && "$servidor" == "IP"} {
			catch { mysqlclose $manejador }
			set manejador ""
			::winix::consola_mensaje "[::thread::id] -> $manejador <- $tipo" 20
		}
	}

	method abrir_manejador { } {
		if { "$manejador" == "" } {
			switch -- $servidor {
				Normal {
					set manejador [ ::winix::obtiene_valor base_LAN]
				}
				Local {
					set manejador [ ::winix::obtiene_valor base_LAN ]
				}
				Central {
					set manejador [ ::winix::obtiene_valor base_WAN]
				}
				Temporal {
				}
				IP {
					if [ catch { 
						if {"$ssl" == "Cierto"} {
							set manejador [mysqlconnect -host $ip \
									-user $usuario \
									-password $clave  \
									-ssl True \
									-sslkey  $sslkey \
									-sslcert $sslcert \
									-sslca   $sslca \
									-compress true ]
						} else {
							set manejador [mysqlconnect -host $ip \
									-user $usuario \
									-password $clave \
									-compress true ]
						}
						::winix::consola_mensaje "[::thread::id] -> $manejador" 20

					} resultado ] {
						mensaje_log "ERROR: $resultado $ip" Conexion IP
						problemas "Error al conectar a la base de datos $ip" $resultado
					}
					catch {
						mysqluse $manejador [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ] 
					}
				}
			}
		}
	}

	method base_datos { tab } {
		variable tablas_sincronizacion

		set basedatos [ ::winix::obtiene_valor db ]

		if [ catch {
			# Revisa a que base de datos pertenece la tabla
			switch -- $tablas_sincronizacion($tab) {
				"sistema"	{ 
					if { "$bd_sistema" == "" } {
						set basedatos [ ::winix::obtiene_valor sistemasdb ]
					} else {
						set basedatos $bd_sistema
					}
				}
				"dim_mt"	{ 
					if { "$bd_winix" == "" } {
						set basedatos [ ::winix::obtiene_valor dimdb]
					} else {
						set basedatos $bd_winix
					}
				}
				default		{
					if [ info exist arreglo_basedatos($tab) ] {
						set basedatos arreglo_basedatos($tab)
					} else {
						if { "$bd_datos" == "" } {
							set basedatos [ ::winix::obtiene_valor db]
						} else {
							set basedatos $bd_datos
						}
					}
				}
			}
		} resultado ] {
			::winix::consola_mensaje "Error paara verificar base de datos de la tabla $resultado" -4
		}
		return $basedatos
	}

	method sql { cadena args } {
		set modalidad "Consulta"

		foreach {par val} $args {
			switch -- $par {
				-Modalidad {
					set modalidad $val
				}
			}
		}

		debug "Ejecutando cadena SQL modalidad $servidor ($ip) modalidad consulta ($modalidad): $cadena" 5

# -------------------------------------------------Corregir la decision de 
#				Normal, si esta en linea es WAN y si esta diferido o dedicado es LAN
#				Central, si esta en linea se conecta, si no devuelve nada
#				Temporal, establecer una conexion nueva
#				IP Se establece la conexion al servidor especificado en -IP, cuando -Servidor es IP

		abrir_manejador

		switch -- "$modalidad" {
			"Consulta" {
				if [ catch {
					set res ""
					debug "Ejecutando consulta en mysql ( $cadena )" 12
					set res [mysqlsel $manejador $cadena -list] 
		
					set registros [expr [::mysql::result $manejador current ] + [::mysql::result $manejador rows ] ]
					set numero_campos [::mysql::result $manejador cols ] 
					set campos [::mysql::col $manejador -current name]
		
		
				} resultado ] {
					::bitacora::mensaje "SQL $servidor: $resultado $cadena"
					problemas "Sucedio un problema con la conexion a la base de datos, con la sentencia $cadena " $resultado
					if {"$servidor" == "IP" && "$persistente" != "Cierto" } {
						cerrar_manejador Err
					}
					return ""
				}
			}
			"Ejecutar"  {
				if [ catch {
					debug "Ejecutando comando en mysql ( $cadena )" 12
					mysqlexec $manejador $cadena
				} resultado ] {
					::bitacora::mensaje "SQL $servidor: $resultado $cadena"
					problemas "Sucedio un problema con la conexion a la base de datos, con la sentencia $cadena " $resultado
					debug "Error con el comando ( $resultado )" 10
					if {"$servidor" == "IP" && "$persistente" != "Cierto" } {
						cerrar_manejador Err
					}
					return -1
				} else {
					debug "Aparentemente se grabo bien" 5
				}
				if {"$servidor" == "IP" && "$persistente" != "Cierto" } {
					cerrar_manejador Ejecutar
				}
				return ""
			}
			"Cerrar"  {
				if {"$servidor" == "IP" } {
					cerrar_manejador Peticion
				}
				return ""
			}
		}

		cerrar_manejador Termino

		debug "-------------Datos de la rutinas sql-------------------" 13
		debug "Registros     : $registros" 13
		debug "Campos        : $numero_campos" 13
		debug "Nombres Campos: $campos" 13
		debug "Informacio de registros: $res" 13

		set control_sql [list $res $campos $registros $numero_campos ]

		return $control_sql
	}
}
