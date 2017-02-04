#!/bin/echo "Este programa solo puede ejecutarse desde el sistema"

##############################################################################
# Sistema de Desarrollo Winix
#
# Autor: Ricardo Cuevas Camarena
# Proyecto: winix
# Archivo: rutinas.tcl
# 
# Descripcion: Rutinas Auxiliares
#
# Derechos Reservados 2005,2006 Derechos Reservados
##############################################################################

# Variable para controlar que no se muestra la ventana de error grave 2 o mas veces
set ::trono 0

# -------------------------
# Graba mensaje en bitacora
# -------------------------
proc mensaje_log { mensaje {base ""} {tabla ""} } {

    set varfecha [clock format [clock seconds] -format "%d/%m/%Y" ]
    set varhora [clock format [clock seconds] -format "%H:%M" ]

    debug "$mensaje $base $tabla"

    if [catch { set archivo_log [open "[::winix::obtiene_valor bitacora_en_disco ./bitacora.log]" a] } resultado ] {
        return
    }

    puts $archivo_log [format "%10s %5s %10s   %-25s %-15s %s" $varfecha $varhora $base $tabla [::winix::obtiene_valor usuario Error]    $mensaje]
    close $archivo_log
}

# -------------------------------------
# Lee configuracion de la base de datos
# -------------------------------------
proc carga_configuracion_sqlite { } {
	sqlite3 sqlite_configuracion [::winix::obtiene_valor archivo_configuracion ] -readonly 1

	set configuracion [ sqlite_configuracion eval "
		select variable, valor 
			from configuracion
			where variable = 'compatible_2'
		"]

	foreach { var val } $configuracion {
		set ::winix::configuracion($var) $val
	}

	set configuracion [ sqlite_configuracion eval "
		select variable, valor 
			from configuracion
		"]

	foreach { var val} $configuracion {
		::winix::asigna_valor $var $val Cargador Sqlite
	}

	sqlite_configuracion close
}

# ------------------------------------
# Conecta a la base de datos principal
# ------------------------------------

proc conecta_base_general { } {
	if {"[::winix::obtiene_valor dedicado Cierto]" eq "Cierto"} {
		::winix::asigna_valor servidor_WAN [::winix::obtiene_valor servidor_LAN localhost] Cargador "Validacion dedicado = Cierto"
		debug "Conexion exclusiva a un servidor"
		::winix::asigna_valor desconectado 0 Cargador "Validacion dedicado = Cierto"
		::winix::asigna_valor estado_conexion "Conexion Exclusiva a un servidor" Cargador "Validacion dedicado = Cierto"
		return
	}

	debug "Conectandose a la base de datos general -host [::winix::obtiene_valor servidor_WAN] -user [::winix::obtiene_valor usuario Error] -password **********"

	if {"[::winix::obtiene_valor ssl Falso]" == "Cierto"} {
		if [ catch { ::winix::asigna_valor base_WAN [mysqlconnect \
			-host [::winix::obtiene_valor servidor_WAN localhost] \
			-user [::winix::obtiene_valor usuario Error] \
			-password [::winix::obtiene_valor clave] \
			-ssl True \
			-sslkey  [ ::winix::obtiene_valor sslkey ] \
			-sslcert [ ::winix::obtiene_valor sslcert ] \
			-sslca   [ ::winix::obtiene_valor sslca ] \
			-compress true 
		] Cargador Conexion } resultado ] {
			debug "No se pudo conectar al servidor WAN $resultado"
			modo_diferido $resultado
		} else {
			::winix::asigna_valor desconectado 0 Cargador "Conexion establecida"
			::winix::asigna_valor estado_conexion "En Linea" Cargador "Conexion establecida"
		}
	} else {
		if [ catch { ::winix::asigna_valor base_WAN [mysqlconnect \
			-host [::winix::obtiene_valor servidor_WAN localhost] \
			-user [::winix::obtiene_valor usuario Error] \
			-password [::winix::obtiene_valor clave] \
			-compress true
		] Cargador Conexion } resultado ] {
			debug "No se pudo conectar al servidor WAN $resultado"
			modo_diferido $resultado
		} else {
			::winix::asigna_valor desconectado 0 Cargador "Conexion establecida"
			::winix::asigna_valor estado_conexion "En Linea" Cargador "Conexion establecida"
		}
	}

	::winix::consola_mensaje "[::thread::id] -> [::winix::obtiene_valor base_WAN] ---->WAN" 20
    
	debug "Estado de la conexion WAN [::winix::obtiene_valor desconectado 0]"
}

# -------------------------------------------------------------------------------
# Pasa a modo diferido cuando hay problemas para conectarse al servidor principal
# -------------------------------------------------------------------------------

proc esta_diferido { } {
	if {"[::winix::obtiene_valor estado_conexion {Proceso Diferido}]" == "Proceso Diferido" } {
		return 1
	} else {
		return 0
	}
}

# ------------------------------------
# Carga rutinas auxiliares del sistema
# ------------------------------------

proc cargar_catalogo_programas { } {
	if {"[::winix::obtiene_valor programas bd ]" != "disco"} {
		return
	}

	set definicion_disco_proyecto {
		proyecto/instancias 	instancias	tcl
		proyecto/procesos 	procesos	tcl
	}

	set definicion_disco_winix {
		winix/clases		clases 		itcl
		winix/configuracion	configuracion	cfg
		winix/instancias	instancias	tcl
		winix/procesos		procesos	tcl
		winix/programas		programas	tcl
		winix/rutinas		rutinas		tcl
	}

	foreach { directorio tipo extension} $definicion_disco_proyecto {
		set archivos_instancias [glob [::winix::obtiene_valor directorio . ]/$directorio/*.$extension]
		foreach { instancia_proyecto } $archivos_instancias {
			mensaje_log "Cargando $instancia_proyecto"
			set arc [open $instancia_proyecto r]
			set registro [read $arc]
			close $arc
			set codigo [lindex $registro 0]
			lappend registro proyecto
			set ::catalogo_programas($codigo) $registro 
		}
	}

	foreach { directorio tipo extension} $definicion_disco_winix {
		set archivos_winix [glob [::winix::obtiene_valor directorio . ]/$directorio/*.$extension]
		foreach { clase_winix } $archivos_winix {
			mensaje_log "Cargando $clase_winix"
			set arc [open $clase_winix r]
			set registro [read $arc]
			close $arc
			set codigo [lindex $registro 0]
			lappend registro winix
			set ::catalogo_programas($codigo) $registro
		}
	}

}

# ------------------------------------
# Carga rutinas auxiliares del sistema
# ------------------------------------

proc cargar_rutinas { } {
	if {"[::winix::obtiene_valor programas bd ]" == "bd"} {
		cargar_rutinas_bd
	} else {
		cargar_rutinas_disco
	}
}

proc cargar_clases { } {
	if {"[::winix::obtiene_valor programas bd ]" == "bd"} {
		cargar_clases_bd
	} else {
		cargar_clases_disco
	}
}

proc cargar_procesos { } {
	if {"[::winix::obtiene_valor programas bd ]" == "bd"} {
		cargar_procesos_bd
	} else {
		cargar_procesos_disco
	}
}

proc cargar_configuraciones { } {
	if {"[::winix::obtiene_valor programas bd ]" == "bd"} {
		cargar_configuraciones_bd
	} else {
		cargar_configuraciones_disco
	}
}

# ------------------------------------
# Carga rutinas auxiliares del sistema de disco
# ------------------------------------

proc cargar_rutinas_disco { } {
	debug "Cargando rutinas internas con opcion [::winix::obtiene_valor programas bd ]"
	set ::winix_generales(base_datos) sistemasdb
	foreach {tipo_elegido origen_elegido descripcion_tipo} { 
			Rutinas proyecto  "Rutinas"
			Rutinas winix	  "Rutinas Winix"
			Clases  winix     "Clases Winix"
			Proceso proyecto "Procesos Globales"
			Proceso winix    "Procesos Winix"
			Configuracion winix "Configuraciones Winix"
		} {
		debug "Cargando $descripcion_tipo con opcion [::winix::obtiene_valor programas bd ]"
		avance "Cargando sistema principal... $descripcion_tipo."

		foreach codigo [array names ::catalogo_programas] {
			set ind 0
			foreach {var} {codigo descripcion tipo usuario programa origen} {
				set $var [lindex $::catalogo_programas($codigo) $ind]
				incr ind
			}
			if {"$origen" == "$origen_elegido" && "$tipo" == "$tipo_elegido" } {
				debug "Cargando $codigo - $tipo - $origen" 12
				set ::winix_generales(codigo) $codigo
				set ::winix_generales(descripcion) $descripcion
				debug $programa 13
				if [ catch { eval $programa } resultado ] {
					tronar $resultado rutinas $usuario
				}
			}
		}
	}
}

proc error_hilo { hilo problema } {
	if { "[::winix::obtiene_valor modalidad texto]" == "texto" } {
		puts "==================================================="
		puts "=    Error grave, tuvimos problemas en un hilo    ="
		puts "==================================================="
		puts "==================================================="
		puts "==================================================="
		puts "Hilo: $hilo"
		puts "==================================================="
		puts "$problema"
		puts "==================================================="
	} else {
		catch {
			toplevel .hilote
			text .hilote.log
			pack .hilote.log
		}
		.hilote.log insert end "Hilo $hilo\n"
		.hilote.log insert end "$problema\n\n"
	}
}


package provide bitacora 1.0

namespace eval bitacora {

	namespace export mensaje

	proc mensaje { mensaje } {                
        
		debug "De la bitacora $mensaje" 1
	}
}

