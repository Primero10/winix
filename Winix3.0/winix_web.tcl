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

# ------------------------
# Arma el menu del sistema
# ------------------------

proc ::winix::seccion-temas-web {} {
	if { "[::winix::obtiene_valor witc_temas_activado true]" == "true" } {
		return {
			<li><a href=# >Tema:
			<select id=themes onchange=window.cambia_tema(this);>
				<option value=/jquery-ui/themes/black-tie/jquery-ui.css>black-tie</option>
				<option value=/jquery-ui/themes/blitzer/jquery-ui.css>blitzer</option>
				<option value=/jquery-ui/themes/cupertino/jquery-ui.css>cupertino</option>
				<option value=/jquery-ui/themes/dark-hive/jquery-ui.css>dark-hive</option>
				<option value=/jquery-ui/themes/dot-luv/jquery-ui.css>dot-luv</option>
				<option value=/jquery-ui/themes/eggplant/jquery-ui.css>eggplant</option>
				<option value=/jquery-ui/themes/excite-bike/jquery-ui.css>excite-bike</option>
				<option value=/jquery-ui/themes/flick/jquery-ui.css>flick</option>
				<option value=/jquery-ui/themes/hot-sneaks/jquery-ui.css>hot-sneaks</option>
				<option value=/jquery-ui/themes/humanity/jquery-ui.css>humanity</option>
				<option value=/jquery-ui/themes/le-frog/jquery-ui.css>le-frog</option>
				<option value=/jquery-ui/themes/mint-choc/jquery-ui.css>mint-choc</option>
				<option value=/jquery-ui/themes/overcast/jquery-ui.css>overcast</option>
				<option value=/jquery-ui/themes/pepper-grinder/jquery-ui.css>pepper-grinder</option>
				<option value=/jquery-ui/themes/redmond/jquery-ui.css>redmond</option>
				<option value=/jquery-ui/themes/smoothness/jquery-ui.css>smoothness</option>
				<option value=/jquery-ui/themes/south-street/jquery-ui.css>south-street</option>
				<option value=/jquery-ui/themes/start/jquery-ui.css>start</option>
				<option value=/jquery-ui/themes/sunny/jquery-ui.css>sunny</option>
				<option value=/jquery-ui/themes/swanky-purse/jquery-ui.css>swanky-purse</option>
				<option value=/jquery-ui/themes/trontastic/jquery-ui.css>trontastic</option>
				<option value=/jquery-ui/themes/ui-darkness/jquery-ui.css>ui-darkness</option>
				<option value=/jquery-ui/themes/ui-lightness/jquery-ui.css>ui-lightness</option>
				<option value=/jquery-ui/themes/vader/jquery-ui.css>vader</option>
			</select>
			</a>
		}
	} else {
		return ""
	}
}
proc ::winix::administrador { } {
	::winix::consola_mensaje "Armando consola de administracion" 16

        set admin_html [ subst {
		<!DOCTYPE html>
		<html lang="en" >
		<head>
			<meta charset="iso8859-1" />
			<title>[::winix::obtiene_valor sistema] (Ventana de administracion del sistema)</title>
			<link rel="stylesheet" href="estetica/[::winix::obtiene_valor web_estetica_estado 000018]" type="text/css" media="screen">
			<link rel="stylesheet" href="estetica/[::winix::obtiene_valor web_estetica_programa 000019]" type="text/css" media="screen">			<link rel="stylesheet" href="//code.jquery.com/ui/1.11.2/themes/smoothness/jquery-ui.css">
			<script src="https://code.jquery.com/jquery-1.11.2.js"></script>
			<script src="/jquery-ui-1.11.2/jquery-ui.js"></script>
			<script src="src/ace.js" type="text/javascript" charset="utf-8"></script>
			<script>
				var connection = new WebSocket('[::winix::obtiene_valor web_dominio_wss ][::winix::obtiene_valor web_puerto_url ]/wss/[::winix::obtiene_valor sesion]');
			</script>
			<script src="BASEDIM/000003" type="text/javascript"></script>
			<style>
				label {
					display: inline-block;
					margin-right: 5px;
					text-align: right;
				}
				.usuarios_listado tr:hover {
				  background: #fbf8e9;
				  transition: all 0.1s ease-in-out;     
				}
				
				.usuarios_listado {
				    font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
				    width: 100%;
				    border-collapse: collapse;
				}
				
				.usuarios_listado td, .usuarios_listado th {
				    font-size: 1em;
				    border: 1px solid #98bf21;
				    padding: 3px 7px 2px 7px;
				}
				
				.usuarios_listado th {
				    font-size: 1.1em;
				    text-align: left;
				    padding-top: 5px;
				    padding-bottom: 4px;
				    background-color: #444444;
				    color: #ffffff;
				}
				
				.usuarios_listado tr.alt td {
				    color: #000000;
				    background-color: #EAF2D3;
				}			
			</style>
    		</head>
		<body>
			<style type="text/css">
				body
 				{
					background-image: url(imagenes/[::winix::obtiene_valor fondo fondo.jpg]);
					background-repeat: no-repeat;
				}
			</style>
			<table width=100%>
			<tr><td colspan=2>
			<img src=imagenes/logo_login_web.png align="left">
			<div id=estado></div>
			</td></tr>
			<tr><td>
			<fieldset>
			<legend>Conexiones al servidor</legend>
			<div id=usuarios>
			</div>
			</legend>
			</td>
			<td>
		        <div id=principal>
		        </div>
		        </td>
		        </tr></table>
			<div id="instancias">
			</div>
			<div id="editor">
			</div>
			<fieldset>
			<legend>Depuracion de código</legend>
			 <button onclick=document.getElementById("debug").innerHTML="";>
			Limpiar debug</button>
			</fieldset>.
			<div id="debug">
			</div>
			</legend>
	    	</body>
	</html>
	} ]

	return "$admin_html"
}

proc ::winix::estructura_menu { } {
	if { [::winix::obtiene_valor menu "" ] == "" } { return }

	::winix::navegador -comando MENU -subcomando PREPARA -modo [::winix::obtiene_valor estilo-menu smartmenu]

	set cantidad [ llength [::winix::obtiene_valor menu "" ] ]
	set pasos [ expr 50 / $cantidad ]
	set av 50
	
	foreach { grupo opcion programa atajo nivel etapa } [::winix::obtiene_valor menu "" ] {
		if [ info exist menues($grupo) ] {
		} else {
			set homo [ join [ split [string map { / - á a é e í i ó o ú u } $grupo] ] _ ]
			set ruta [split $homo - ]
			set profundidad [ llength $ruta ]
			set padre [ join [ lrange $ruta 0 [ expr $profundidad - 2 ] ] - ]
			set hijo [ lindex $ruta [ expr $profundidad - 1 ] ]
			if [ info exist menues([lindex $ruta 0])] {
			} else {
				set menues([lindex $ruta 0]) ""
				::winix::navegador -comando MENU -subcomando PRINCIPAL -menu "[ join [ split [lindex $ruta 0] _ ] ]" -submenu "menu-[lindex $ruta 0]" -avance $av -modo [::winix::obtiene_valor estilo-menu smartmenu]
				debug "Poniendo menu principal menu-[lindex $ruta 0] en menu"
			}
			set padre [lindex $ruta 0]
			set parcial [lindex $ruta 0]
			foreach men [lrange $ruta 1 end] {
				append parcial "-$men"
				if [ info exist menues($parcial)] {
				} else {
					set menues($parcial) ""
					::winix::navegador -comando MENU -subcomando SUBMENU -objeto "menu-$padre" -letrero "[ join [ split [lindex $men 0] _ ] ]" -submenu "menu-$parcial" -avance $av -modo [::winix::obtiene_valor estilo-menu smartmenu]
					set padre $parcial
					debug "Poniendo menu principal menu-$parcial en menu-$padre"
				}
			}
		}
		::winix::navegador -comando MENU -subcomando OPCION -objeto "menu-$homo" -submenu "$opcion" -programa "$programa" -avance $av -modo [::winix::obtiene_valor estilo-menu smartmenu]
		set ::niveles($programa) $nivel
		set av [expr $av + $pasos]
	}
#	if { "[::winix::obtiene_valor plataforma]" != "web" } {
#		::winix::navegador -comando MENU -subcomando PRINCIPAL -menu "<li><a href=[::winix::obtiene_valor web_dominio][::winix::obtiene_valor web_puerto_url ]>Salir</a></li>" -modo [::winix::obtiene_valor estilo-menu smartmenu]
#	}
	::winix::navegador -comando MENU -subcomando ACTIVAR -modo [::winix::obtiene_valor estilo-menu smartmenu]
	avance "Armando menus...Terminado" 100 
}

proc ::winix::ingresar { modalidad } {
	switch $modalidad {
		web {
			::winix::consola_mensaje "Cargando configuracion completa" 5
			set resultado [obtiene_configuracion servidor]

			if {"$resultado" == ""} {
				::winix::consola_mensaje "Cargando sistema principal..." 5
				cargar_catalogo_programas
				::winix::consola_mensaje "Cargando rutinas..." 5
				cargar_rutinas
				::winix::consola_mensaje "Cargando clases..." 5
				cargar_clases
				::winix::consola_mensaje "Cargando configuraciones..." 5
				cargar_configuraciones
				::winix::consola_mensaje "Leyendo menus de web..." 5
				obtiene_menu_del_usuario web web
		
				return 1
			} else {
				return 0
			}
		}
		solo_valida {
			::winix::consola_mensaje "Validando usuario" 16
			set resultado [obtiene_configuracion solo_valida]
			::winix::consola_mensaje "Resultado de la validacion $resultado" 16
			if {"$resultado" == ""} {
				return 1
			} else {
				return 0
			}
		}
		default {
			::winix::consola_mensaje "No reconozco la modalidad $modalidad, hay que verificar el codigo" 16
			return 0
		}
	}
}

proc ::winix::upgrade_conexion_witc { usuario clave } {
	after 50 [ list ::winix::procesa_upgrade $usuario $clave ]
}

proc ::winix::procesa_upgrade { usuario clave } {
	::winix::asigna_valor plataforma witc
	obtiene_configuracion cambia_usuario $usuario $clave
	cargar_procesos
	obtiene_menu_del_usuario witc $usuario

	::winix::navegador \
		-comando HTML \
		-subcomando ASIGNA \
		-objeto principal \
		-contenido "[::winix::portal_carga_pagina [::winix::obtiene_valor web_witc_homepage ] ]"

	::winix::estructura_menu
	
	::winix::estado

	::winix::navegador \
		-comando MENSAJERO \
		-usuario $usuario@[::winix::obtiene_valor mensajero_dominio takmab.mx ] \
		-clave $clave \
		-bosh "https://[::winix::obtiene_valor mensajero_servidor mensajeria.takmab.mx ]:[::winix::obtiene_valor mensajero_puerto 5281 ]/[::winix::obtiene_valor mensajero_directorio http-bind]/"

	::winix::consola_mensaje "Thread de instancias subido a $usuario [::thread::id]" 2

	::tsv::set usuarios [::thread::id] $usuario
	::tsv::set programas [::thread::id] ""
}

proc ::winix::downgrade_conexion_witc { usuario clave } {
	if { "[::winix::obtiene_valor usuario]" == "web" } {
		return
	}
	::winix::asigna_valor plataforma web
	obtiene_configuracion cambia_usuario $usuario $clave
	obtiene_menu_del_usuario web web

	::winix::consola_mensaje "Thread de instancias bajado [::thread::id]" 2

	::tsv::set usuarios [::thread::id] $usuario
	::tsv::set programas [::thread::id] ""
}

proc ::winix::estado {  } {
	set resultado ""
	if [ catch { 
		::winix::navegador -comando ESTADO -estado "
			<ul>
			<li><a href=# >Mensajes:[::winix::obtiene_valor mensajes 0]</a>
			<li><a href=# >Sucursal:[::winix::obtiene_valor sucursal Indefinida]</a>
			<li><a href=# >LAN IP:[::winix::obtiene_valor servidor_LAN Indefinida]</a>
			<li><a href=# >Base de datos:[::winix::obtiene_valor db Indefinida]</a>
			<li><a href=# >Usuario:[::winix::obtiene_valor usuario Indefinida]</a>
			<li><a href=# >Idioma:[::winix::obtiene_valor idioma Indefinida]</a>
			<li><a href=/ >Salir</a>
			</ul>
		"
#			::winix::depuracion "Programando estado [after [ expr [::winix::obtiene_valor segundos_revision_mensajes 60 ] * 1000 ] [ list ::winix::estado 1 ]] despues de [::winix::obtiene_valor segundos_revision_mensajes 60 ] segundos"
		#after 60000 [ list ::winix::estado ]
	} resultado ] {
		::winix::depuracion "Problemas al poner el estado $resultado"
	}
}

proc ::winix::estado_administrador {  } {
	::winix::consolas_administrador -comando ESTADO -estado "
		<ul>
		<li><a href=# >Conexiones:[::winix::obtiene_valor web_adm_hilos 0]</a>
		</ul>
	"
}

proc cargar { programa { nivel ""} {proceso_adjunto ""} } {
	global tipo_programa

	debug "Cargando programa $programa con opcion [::winix::obtiene_valor programas bd ] nivel $nivel"

	switch [::winix::obtiene_valor programas bd ] {
		bd {
			set nivel [::winix::obtiene_nivel $programa]
			set programa [string tolower $programa]
			
			if { "$nivel" == "" } { return }

			set ::winix_generales(base_datos) dimdb
      			set reg [ ::winix::objeto_consulta consulta_express "
               			select Programa,TipoPrograma,Descripcion
               			from <*entorno_trabajo*>
               			where Codigo = '$programa'
					and Etapa != 'Disponible'
			" flatlist ]

			if {$reg == ""} {
				set ::winix_generales(base_datos)  sistemasdb

				set reg [ ::winix::objeto_consulta consulta_express "
					select Programa,TipoPrograma,Descripcion from <*programas*>
					where Codigo = '$programa' 
					and (Proyecto = 'BASEDIM' or Proyecto = '[::winix::obtiene_valor proyecto WINIX ]')
					and Etapa != 'Disponible'
                		" flatlist ]
			}
		
			if {$reg == ""} {
      				return
			}

			set codigo [lindex $reg 0]
			set tipo_programa [lindex $reg 1]
			set descripcion [lindex $reg 2]
		}
		disco {
			set programa_disco [string toupper $programa]
			if [info exist ::catalogo_programas($programa_disco)] {
				set descripcion [lindex $::catalogo_programas($programa_disco) 1]
				set tipo_programa [lindex $::catalogo_programas($programa_disco) 2]
				set usuario [lindex $::catalogo_programas($programa_disco) 3]
				set codigo [lindex $::catalogo_programas($programa_disco) 4]
			} else {
				debug "No existe en el catalogo de disco $programa" 5
				return
			}
		}
	}
	set ::winix_generales(codigo) $codigo
	set ::winix_generales(descripcion) $descripcion

	if {$tipo_programa == "Proceso"} {
		eval $codigo
		return
	}

	if {$tipo_programa == "Multi-Instancia"} {
		set codigo_instancia ""
		if {"$codigo_instancia" == ""} {
		} else {
			regsub -all {espacio_de_nombre} $codigo $codigo_instancia codigo_destino
			set codigo $codigo_destino
			regsub -all {nombre_de_instancia_original} $codigo $programa codigo_destino
			set codigo $codigo_destino
		}
	} else {
		set codigo_instancia $programa

		catch {
			namespace delete ::${programa}
		}
	}

	set ::programas($programa) $tipo_programa
	set ::niveles($programa)   $nivel

	::winix::consola_mensaje "Evaluando la instancia $programa" 18
	set ::winix_generales(programa) $programa

	debug "ejecutaremos el programa $programa"
	
	if [ catch { eval $codigo } res ] {
		::winix::consola_mensaje "No pudo cargarse instancia $res" 21
		return
	}
	

	set programa $codigo_instancia

	::winix::consola_mensaje "Lanzando metodo ::${programa}::inicia" 18
	
	if [ catch { ::${programa}::inicia } res ] {
		::winix::navegador -comando MENSAJE -contenido "ERROR:\nVerifique el programa\nnecesita poner el proceso inicia\nreporte a sistemas\n$res: $::errorInfo"
		::winix::consola_mensaje "Instancia fallo al ejecutar inicia $res: $::errorInfo" 21
		return
	} else {
		::winix::asigna_programa $programa
	}

	::winix::consola_mensaje "Se supone terminamos" 18

	if {"$proceso_adjunto" != "" } {
		eval $proceso_adjunto
	}
}

proc cargar_de_memoria { codigo programa tipo_programa nivel} {

	if {$tipo_programa == "Multi-Instancia"} {
		return
	}

	catch {
		namespace delete ::${codigo}
	}

	set ::niveles($codigo) $nivel

	debug "ejecutaremos el programa $codigo"
	
	if [ catch { eval $programa } res ] {
		::winix::consola_mensaje "No pudo cargarse instancia $res: $::errorInfo" 18
		return
	}

	if {$tipo_programa == "Instancia"} {
		if [ catch { ::${codigo}::inicia } res ] {
			::winix::navegador -comando MENSAJE -contenido "ERROR:\nVerifique el programa\nnecesita poner el proceso inicia\nreporte a sistemas\n$res: $::errorInfo"
		}
	}
}

proc tronar { resultado fase { usuario sin_usuario} { codigo "" } } {
	::winix::consola_mensaje "Por culpa de $usuario, en el codigo $codigo tenemos un " -1
	::winix::consola_mensaje "Errores al cargar $fase $resultado" -1 tronar
}

# ------------------------------
# Reporta mensajes de depuracion
# ------------------------------

proc debug { mensaje {nivel 1} { consola gui } } {
	if {"[::winix::obtiene_valor debug true ]" != "true"} {
		return
	}
	if {[::winix::obtiene_valor nivel 5 ] < $nivel} {
		return
	}
	if {[::winix::obtiene_valor nivel 5 ] == -3} {
		return
	}

	puts "\[[::winix::obtiene_valor servidor_web Maestro]\] $nivel -> $mensaje"
	
	if { "$consola" == "web" } {
	  ::winix::consola_mensaje $mensaje $nivel
	}
}

proc complementa_configuracion {} {
}

proc termina { } {
# aqui deberiamos limpiar la session del usuario
}

proc modo_diferido { {buffer ""} } {

	debug "Cambiando a modo diferido debido a $buffer"

	::winix::asigna_valor desconectado 	1 			Evento "Fallo algo $buffer"
	::winix::asigna_valor actualizado  	0 			Evento "Fallo algo $buffer"
	::winix::asigna_valor estado_conexion 	"Proceso Diferido"	Evento "Fallo algo $buffer"

}

proc problemas {problema motivo} {

    if {$::trono == 0} {
        # set ::trono 1

        set var_texto $motivo
        # Verifica si el error es por la contraseï¿½ para avisar al usuario.
        set res [string first "Access denied" $motivo]
        if { $res >= 0 } {
            set var_texto "Acceso Negado. Verifique la clave, cuidando maysculas y minsculas"
        }
        # Verifica si el error es un campo desconocido para avisar al usuario y
        # pedirle que notifique de esto al administrador
        set res [string first "Unknown column" $motivo]
        if { $res >= 0 } {
            set campo [lindex $motivo 4]
            set var_texto "Campo desconocido: $campo . Notifique de inmediato al administrador"
        }

	::winix::consola_mensaje "$problema \n \nERROR:  $var_texto" -1
	
    }
}

# ------------------------------------
# Carga rutinas auxiliares del sistema de base de datos
# ------------------------------------

proc cargar_rutinas_bd { } {
	debug "Cargando rutinas internas con opcion [::winix::obtiene_valor programas bd ]"
	avance "Cargando sistema principal... Rutinas."

        debug "Cargando rutinas de Proyecto [::winix::obtiene_valor proyecto WINIX ]" 4
	set ::winix_generales(base_datos) sistemasdb
	set programas [ ::winix::objeto_consulta consulta_express "
		select Codigo,Programa,UsuarioModificacion,Descripcion 
			from <*programas*>
		where TipoPrograma = 'Rutinas' 
		and (Proyecto = 'BASEDIM' 
		or Proyecto = '[::winix::obtiene_valor proyecto WINIX ]')
	" flatlist ]

	foreach {codigo programa usuario descripcion} $programas {
		set ::winix_generales(codigo) $codigo
		set ::winix_generales(descripcion) $descripcion
		debug "Cargando $codigo modificado por $usuario .- $descripcion" 2
		debug $programa 21
		if [ catch { eval $programa } resultado ] {
			tronar "$resultado" rutinas $usuario $codigo
		}
	        debug "Cargando $codigo modificado por $usuario .- $descripcion <-terminado"  4
	}

	avance "Cargando sistema principal... Rutinas Winix."
        debug "Cargando rutinas de Winix" 4
	# CARGANDO RUTINAS DE LA TABLA DIM_MT
	set ::winix_generales(base_datos) dimdb
	set programas [ ::winix::objeto_consulta consulta_express "
        	select Codigo,Programa,UsuarioModificacion,Descripcion 
        	from <*entorno_trabajo*>
        	where   TipoPrograma = 'Rutinas' order by Codigo
	" flatlist ]
	
	foreach {codigo programa usuario descripcion} $programas {
		set ::winix_generales(codigo) $codigo
		set ::winix_generales(descripcion) $descripcion
	        debug "Cargando $codigo modificado por $usuario .- $descripcion"  4
	        debug $programa 21
	        if [ catch { eval $programa } resultado ] {
			tronar "$resultado" rutinas_winix $usuario $codigo
        	}
	        debug "Cargando $codigo modificado por $usuario .- $descripcion <-terminado"  4
    	}
	avance "Cargando sistema principal... Rutinas terminado."
}

proc cargar_clases_bd { } { 
	debug "Cargando clases con opcion [::winix::obtiene_valor programas bd ]"	

	avance "Cargando sistema principal... Clases DIM-MT."
	# CARGANDO CLASES DE LA TABLA DIM_MT
	set ::winix_generales(base_datos)  dimdb
	set programas [ ::winix::objeto_consulta consulta_express "
        	select Codigo,Programa,UsuarioModificacion,Descripcion 
        	from <*entorno_trabajo*>
        	where   TipoPrograma = 'Clases'
    	" flatlist ]
    
	foreach {codigo programa usuario descripcion} $programas {
		set ::winix_generales(codigo) $codigo
		set ::winix_generales(descripcion) $descripcion
        	debug "Cargando $codigo modificado por $usuario .- $descripcion" 4
        	debug $programa 21
        	if [ catch { eval $programa } resultado ] {
			tronar "$resultado" clases $usuario $codigo
        	}
    	}

	avance "Cargando sistema principal... Clases WITC."
	# CARGANDO CLASES DE LA TABLA DIM_MT
	set ::winix_generales(base_datos)  dimdb
	set programas [ ::winix::objeto_consulta consulta_express "
		select Codigo,Programa,UsuarioModificacion,Descripcion 
		from <*entorno_trabajo*>
		where   TipoPrograma = 'ClasesWITC'
	" flatlist ]
	
	foreach {codigo programa usuario descripcion} $programas {
		set ::winix_generales(codigo) $codigo
		set ::winix_generales(descripcion) $descripcion
		debug "Cargando $codigo modificado por $usuario .- $descripcion" 4
		debug $programa 21
		if [ catch { eval $programa } resultado ] {
			tronar "$codigo $resultado" clases_witc $usuario $codigo
		}
	}
}

proc cargar_procesos_bd { } {
	debug "Cargando Procesos con opcion [::winix::obtiene_valor programas bd ]"

	avance "Cargando sistema principal... Procesos."
	set ::winix_generales(base_datos)  sistemasdb
	set programas [ ::winix::objeto_consulta consulta_express "
		select Codigo,Programa,UsuarioModificacion,Descripcion 
			from <*programas*>
			where   TipoPrograma = 'Proceso'
			and (Proyecto = 'BASEDIM' or Proyecto = '[::winix::obtiene_valor proyecto WINIX ]')
		" flatlist ]

	foreach {codigo programa usuario descripcion} $programas {
		set ::winix_generales(codigo) $codigo
		set ::winix_generales(descripcion) $descripcion
		debug "Cargando $codigo modificado por $usuario .- $descripcion" 4
		debug $programa 21
		if [ catch { eval $programa } resultado ] {
			tronar $resultado procesos
		}
    	}
    
	avance "Cargando sistema principal... Procesos DIM-MT."
	# CARGANDO PROCESOS DE LA TABLA DIM_MT
	set ::winix_generales(base_datos)  dimdb
	set programas [ ::winix::objeto_consulta consulta_express "
        	select Codigo,Programa,UsuarioModificacion,Descripcion 
        	from <*entorno_trabajo*>
        	where   TipoPrograma = 'Proceso'
    	" flatlist ]

	foreach {codigo programa usuario descripcion} $programas {
		set ::winix_generales(codigo) $codigo
		set ::winix_generales(descripcion) $descripcion
	        debug "Cargando $codigo modificado por $usuario .- $descripcion" 4
	        debug $programa 21
	        if [ catch { eval $programa } resultado ] {
			tronar $resultado procesos
        	}
    	}
}

proc cargar_configuraciones_bd { } {
	debug "Cargando Configuraciones con opcion [::winix::obtiene_valor programas bd ]"
    
	avance "Cargando sistema principal... Configuracion DIM-MT."
	# CARGANDO CONFIGURACION DE LA TABLA DIM_MT
	set ::winix_generales(base_datos)  dimdb
	set programas [ ::winix::objeto_consulta consulta_express "
		select Codigo,Programa,UsuarioModificacion,Descripcion 
		from <*entorno_trabajo*>
		where   TipoPrograma = 'Configuracion'
	" flatlist ]
    
	foreach {codigo programa usuario descripcion} $programas {
		set ::winix_generales(codigo) $codigo
		set ::winix_generales(descripcion) $descripcion
		debug "Cargando $codigo modificado por $usuario .- $descripcion" 4
		debug $programa 21
		if [ catch { eval $programa } resultado ] {
				tronar $resultado clases
		}
   	}

	debug "Cargando Configuraciones GUI con opcion [::winix::obtiene_valor programas bd ]"

}

proc ::winix::portal_carga_pagina { { codigo "" } { parametros "" } { tipo_consulta "general"} } {

	if { "$codigo" == "" } {
		set codigo [ ::winix::obtiene_valor web_homepage "" ]
	}

	if { "$codigo" == "" } {
		return "Pagina vacia"
	}

	if { "$tipo_consulta" == "general" } {
		set registros [ ::winix::objeto_consulta consulta_express "
			SELECT Script,Tipo_Pagina,Parametros
			from <*servidor_web*>
			where Proyecto='[::winix::obtiene_valor proyecto ]' 
			and Codigo='$codigo'" flatlist ]
	} else {
		set registros [ ::winix::objeto_consulta_web consulta_express "
			SELECT Script,Tipo_Pagina,Parametros
			from <*servidor_web*>
			where Proyecto='[::winix::obtiene_valor proyecto ]' 
			and Codigo='$codigo'" flatlist ]
	}


	if { [llength $registros] == 0 } {
		debug "No existe pagina $codigo"
		return ""
	}

	set pagina [lindex $registros 0]
	set tipo [lindex $registros 1]
	set parametros_para_importar [lindex $registros 2]

	switch -- $tipo {
		Pagina {
			set cadena $pagina
		}
		Portal {
			debug "Parametros pasados $parametros"
			set par ""
			foreach { var val } $parametros {
				append par "set $var \"$val\"\n"
			}

			foreach { var } $parametros_para_importar {
				set val [::winix::portal_parametros $var]
				append par "set $var \"$val\"\n"
			}

			set comando ""
			append comando $par \n $pagina

			set cadena ""
			set cadena "[ eval $comando ]"
		}
		Principal {
			set cadena "[ subst $pagina ]"
		}
		default {
			debug "No existe pagina $codigo por que falta tipo"
			return ""
		}
	}
	return $cadena
}

proc ::winix::portal_carga_principal { { codigo "" } } {
	set registros [ ::winix::objeto_consulta_web consulta_express "
		SELECT Script,Tipo_Pagina,Parametros
		from <*servidor_web*>
		where Proyecto='[::winix::obtiene_valor_web proyecto ]' 
		and Codigo='$codigo'" flatlist ]

	if { [llength $registros] == 0 } {
		debug "No existe pagina $codigo"
		return ""
	}

	set pagina [lindex $registros 0]
	set tipo [lindex $registros 1]
	set parametros_para_importar [lindex $registros 2]

	set cadena "[ subst $pagina ]"

	return $cadena
}

proc ::winix::portal_carga_html { { codigo "" } } {

	if {"$codigo" == ""} {
		return "-----"
	}

	set registros [ ::winix::objeto_consulta consulta_express "
		SELECT Script
		from <*servidor_web*>
		where Proyecto='[::winix::obtiene_valor proyecto ]' 
		and Tipo_Pagina='Pagina' and Codigo='$codigo'" flatlist]
	
	if { [llength $registros] == 0 } {
		debug "No existe pagina $codigo"
		return "------"
	}

	set pagina [lindex $registros 0]

	return $pagina
}

proc ::winix::portal_carga_ligas { {formateadas Cierto } } {

	set registros [ ::winix::objeto_consulta consulta_express "
		SELECT Codigo,Letrero_Ligas
		from <*servidor_web*>
		where Proyecto='[::winix::obtiene_valor proyecto ]' and Ligas > 0
		order by Ligas,Codigo" ]

	if { [llength $registros] == 0 } {
		debug "No hay ligas"
		return ""
	}

	switch $formateadas {
		Cierto {
			set cadena {<div id="globalnav"><ul>}

			foreach registro $registros {
				set codigo [lindex $registro 0]
				set liga [lindex $registro 1]
				append cadena "<li><a href=# onclick=window.cargar(\"$codigo\")>$liga</a></li>"
			}

			append cadena "</ul></div>"
		}
		sin_formatear {
			set cadena ""
			foreach registro $registros {
				set codigo [lindex $registro 0]
				set liga [lindex $registro 1]
				lappend cadena "[::winix::obtiene_valor web_dominio][::winix::obtiene_valor web_puerto_url ]/portal/$codigo" $liga
			}
		}
		Directo {
			set cadena ""
			foreach registro $registros {
				set codigo [lindex $registro 0]
				set liga [lindex $registro 1]
				lappend cadena $codigo $liga
			}
		}
	}
	return $cadena
}

proc ::winix::portal_carga_procesos { proyecto tipo { codigo ""} } {

	set cadena_sql "
		SELECT Codigo,Script
		from <*servidor_web*>
		where Proyecto='[::winix::obtiene_valor proyecto ]' 
		and Tipo_Pagina='$tipo'
	"

	if {"$codigo" != ""} {
		append cadena_sql "and Codigo='$codigo'"
	}

	set registros [ ::winix::objeto_consulta consulta_express $cadena_sql flatlist ]
	
	foreach registro $registros {
		set codigo [lindex $registro 0]
		set pagina [lindex $registro 1]
		if [ catch {
			eval $pagina
		} resultado ] { 
			debug "Error evaluando: $codigo\n$::errorInfo"
		}
	}
}

proc ::winix::portal_carga_script { programa websocket { destino main } { parametros "" } } {
	set registros [ ::winix::objeto_consulta consulta_express "
		SELECT Script,Tipo_Pagina,Parametros
		from <*servidor_web*>
		where Proyecto='[::winix::obtiene_valor proyecto ]' 
		and Codigo='$programa'
		and Tipo_pagina='script'" flatlist ]

	if { [llength $registros] == 0 } {
		debug "No existe pagina $programa tipo script"
		return ""
	}

	set cadena_parametros ""
	set indice 0
	foreach { nombre_parametro } [lindex $registros 2] {
	  append cadena_parametros "set $nombre_parametro [lindex $parametros $indice]\n"
	  incr indice 
	}
	set proceso "$cadena_parametros\nset websocket $websocket \nset id $destino\n[lindex $registros 0]"

	::winix::consola_mensaje "Parametros: programa = $programa, script = $proceso" 14

	if [ catch { 
		eval $proceso 
	} resultado ] {
		::winix::consola_mensaje "Error en la sustitucion de script $programa $resultado : $::errorInfo" 1
	}
}

proc ::winix::portal_lee_script { programa } {
	set registros [ ::winix::objeto_consulta consulta_express "
		SELECT Script,Tipo_Pagina,Parametros
		from <*servidor_web*>
		where Proyecto='[::winix::obtiene_valor proyecto ]' 
		and Codigo='$programa'
		and Tipo_pagina='script'" flatlist ]

	if { [llength $registros] == 0 } {
		debug "No existe pagina $programa tipo script"
		return ""
	}

	return [lindex $registros 0]
}

proc ::winix::portal_boton_regresar { {letrero Regresar} } {

	return "	
	<FORM METHOD=post>
	<INPUT TYPE=button width=10% VALUE=\"$letrero\" OnClick=\"history.go(-1);return true;\">
	</FORM>
	"
}

proc ::winix::arrancar { } {
	avance "Cargando librerias......" 20
	debug "El menu cargado es [::winix::obtiene_valor menu]"
#	::winix::cargar_librerias_navegador

	::winix::estructura_menu

	::winix::asigna_programa "Portal"
	
	::winix::portal_carga_script [ ::winix::obtiene_valor web_inicial ] [::winix::obtiene_valor websock ""] main ""
	
}

proc ::winix::cargar_librerias_navegador {} {
	set av 40
	foreach { tipo id ref media charset } "
		stylesheet stylesheet	{estetica/[::winix::obtiene_valor web_estetica_menu 000020]} 				screen  {}
		stylesheet stylesheet	{estetica/[::winix::obtiene_valor web_estetica_estado 000018]} 				screen  {}
		stylesheet stylesheet	{estetica/[::winix::obtiene_valor web_estetica_programa 000019]} 			screen  {}
		stylesheet stylesheet	{estetica/[::winix::obtiene_valor web_css 000005]} 					screen  {}

		stylesheet stylesheet	{/jquery-ui/themes/[::winix::obtiene_valor jquery_tema smoothness]/jquery-ui.css} 	{} 	{}
	        script     {}		{/jquery-ui-1.11.2/jquery-1.11.2.js}							{} 	{}
		script     {}		{/jquery-ui-1.11.2/jquery-ui.js}							{} 	{}
		script     {}		{/jstree/jstree.min.js}									{} 	{}

		script     {}		{/js/handsontable.full.js}								{} 	{}
		script     {}		{/js/jquery.table2csv.min.js}								{} 	{}

		script     {}		{src/ace.js} 										{} 	{utf-8}

		stylesheet stylesheet	{/css/handsontable.full.css} 								{} 	{}
		stylesheet stylesheet	{/jstree/themes/default/style.min.css} 							{} 	{}
	" {
		incr av 3
		::winix::navegador -comando LIBRERIA -tipo $tipo -id $id -ref "[subst $ref]" -media $media -charset $charset -avance $av
	}
}

proc obtiene_configuracion { { modalidad completa } { usuario "" } { clave "" } } {
	switch [::winix::obtiene_valor tipo_servidor mysql] {
		mysql {
			return [ obtiene_configuracion_mysql $modalidad $usuario $clave ]
		}
		sqlite {
			return [ obtiene_configuracion_sqlite ]
		}
		disco {
			return [ obtiene_configuracion_disco ]
		}
	}
}

# -------------------------------------
# Lee configuracion de la base de datos mysql
# -------------------------------------

proc obtiene_configuracion_mysql { modalidad { usuario "" } { clave "" } } {
	if { "$modalidad" == "cambia_usuario" } {
		::winix::asigna_valor usuario $usuario witc "Upgrade desde la pagina web"
		::winix::asigna_valor clave $clave witc "Upgrade desde la pagina web"
		set modalidad completa
		::winix::objeto_consulta cambia_usuario \
			-usuario $usuario \
			-clave   $clave
		::winix::asigna_valor base_LAN [ ::winix::objeto_consulta obtiene_manejador]
	}
	if { "$modalidad" == "servidor" } {
		::winix::objeto_consulta cambia_usuario \
			-usuario [::winix::obtiene_valor web_usuario Error] \
			-clave   [::winix::obtiene_valor web_clave Error]
		::winix::asigna_valor usuario 	[::winix::obtiene_valor web_usuario Error] servidor "Inicio de usuario para servidor web"
		::winix::asigna_valor clave 	[::winix::obtiene_valor web_clave Error]   servidor "Inicio de usuario para servidor web"
		::winix::asigna_valor base_LAN [ ::winix::objeto_consulta obtiene_manejador]
		set modalidad completa
	}

	::winix::consola_mensaje "Pidiendo la configuracion $modalidad $usuario $clave" 1

	switch $modalidad {
		completa {
			avance "Leyendo Configuración del sistema..."
			set conf [ ::winix::objeto_consulta consulta_express "
				select variable,valor
				from <*configuracion_local*> where Usuario = ''
			" flatlist]
			if { "$conf" == "" } {
				mensaje_log " No se encontró ningun registro en la tabla Configuración !!!" [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ] Configuracion
				problemas "Error 04: No hay datos en la tabla de configuraciones !" "El programa no puede iniciar"
			}

			foreach {var val} $conf {
				::winix::asigna_valor $var $val Mysql General
			}

			avance "Leyendo Configuración del usuario..."
			set conf [ ::winix::objeto_consulta consulta_express "
				select variable,valor
				from <*configuracion_local*> 
				where Usuario = '[::winix::obtiene_valor usuario Error]'
			" flatlist]

			avance "Procesando Configuración del usuario..."
			if { "$conf" != "" } {
				foreach {var val} $conf {
					avance "Procesando Configuración del usuario...$var <- $val"
					::winix::asigna_valor $var $val Mysql Usuario
				}
			}

			avance "Leyendo Configuración de Sucursal..."
			set conf [ ::winix::objeto_consulta consulta_express "
				SELECT 
					suc.CodigoEmpresa,
					ser.Host,
					ser.BaseDatos,
					suc.Es_Corporativo,
					suc.CodigoAlmacen,
					suc.Descripcion, 
					emp.Descripcion
				FROM <*catalogosucursales*> as suc
				left join <*catalogosucursales*> as cor
					on suc.CodigoEmpresa = cor.CodigoEmpresa 
						and cor.Es_Corporativo = '1'
				left join <*servidores*> as ser
					on cor.Codigo = ser.Codigo
				left join <*catalogoempresas*> as emp
					on emp.Codigo = suc.CodigoEmpresa
				where suc.Codigo = '[::winix::obtiene_valor codigo_sucursal 001]'
			" flatlist]

			if { "$conf" == "" } {
				mensaje_log " No se encontró ningun registro en la tabla Configuración !!!" [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ] Configuracion
				problemas "Error 07: No hay consistencia con el codigo de sucursal [::winix::obtiene_valor codigo_sucursal 001]" "El programa no puede iniciar"
			}

			::winix::asigna_valor empresa		[lindex $conf 0] "Configuracion Tablas Sistema" "catalogosucursales,servidores,catalgoempresas"
			::winix::asigna_valor servidor_WAN	[lindex $conf 1] "Configuracion Tablas Sistema" "catalogosucursales,servidores,catalgoempresas"
			::winix::asigna_valor db_WAN 		[lindex $conf 2] "Configuracion Tablas Sistema" "catalogosucursales,servidores,catalgoempresas"
			::winix::asigna_valor es_corporativo 	[lindex $conf 3] "Configuracion Tablas Sistema" "catalogosucursales,servidores,catalgoempresas"
			::winix::asigna_valor almacen 		[lindex $conf 4] "Configuracion Tablas Sistema" "catalogosucursales,servidores,catalgoempresas"
			::winix::asigna_valor sucursal	 	[lindex $conf 5] "Configuracion Tablas Sistema" "catalogosucursales,servidores,catalgoempresas"
			::winix::asigna_valor nombre_empresa 	[lindex $conf 6] "Configuracion Tablas Sistema" "catalogosucursales,servidores,catalgoempresas"
			
			if { "[::winix::obtiene_valor es_corporativo 1]" == "1"} {
				::winix::asigna_valor dedicado "Cierto" Cargador"Validacion es_corporativo"
				::winix::asigna_valor es_sucursal 0 Cargador"Validacion es_corporativo"
			} else {
				::winix::asigna_valor es_sucursal 1 Cargador"Validacion es_corporativo"
			}

			if {[::winix::obtiene_valor dedicado Cierto] eq "Cierto"} {
				::winix::asigna_valor servidor_WAN [::winix::obtiene_valor servidor_LAN localhost] Cargador"Validacion dedicado"
			}

			avance "Leyendo Configuración de plataforma..."
			set conf [ ::winix::objeto_consulta consulta_express "
				select variable,valor
				from <*configuracion_local*> 
				where Usuario = 'plataforma_web'
			" flatlist]

			avance "Procesando Configuración de plataforma..."
			if { "$conf" != "" } {
				foreach {var val} $conf {
					avance "Procesando Configuración del usuario...$var <- $val"
					::winix::asigna_valor $var $val Mysql Usuario
				}
			}

			avance "Conectandose a Servidor Central..."
			conecta_base_general
			
			complementa_configuracion
			return ""
		}
		solo_valida_admin {
			::winix::asigna_valor web_administrador Falso Navegador
			avance "Validando base de datos..."
			if {"[::winix::obtiene_valor ssl Falso]" == "Cierto"} {
				if [ catch { 
					set tmp_con [ mysqlconnect \
						-host [::winix::obtiene_valor servidor_LAN localhost] \
						-user [::winix::obtiene_valor usuario Error] \
						-password [::winix::obtiene_valor clave] \
						-ssl True \
						-sslkey  [ ::winix::obtiene_valor sslkey ] \
						-sslcert [ ::winix::obtiene_valor sslcert ] \
						-sslca   [ ::winix::obtiene_valor sslca ] \
					] 
				} resultado ] {
					mensaje_log "ERROR: $resultado" Conexion LOCAL
					return "Error 01: Revise configuracion del sistema. ( [::winix::obtiene_valor servidor_LAN localhost] )"
				}
			} else {
				if [ catch { 
					set tmp_con [ mysqlconnect \
						-host [::winix::obtiene_valor servidor_LAN localhost] \
						-user [::winix::obtiene_valor usuario Error] \
						-password [::winix::obtiene_valor clave] \
					] 
				} resultado ] {
					mensaje_log "ERROR: $resultado" Conexion LOCAL
					return "Error 01: Revise configuracion del sistema. ( [::winix::obtiene_valor servidor_LAN localhost] )"
				}
			}
			
			if [ catch { 
				mysqluse $tmp_con [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ] 
			} resultado ] {
				mensaje_log "LOCAL: $resultado" [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ]
				return "Error 02: Revise configuracion del sistema. ( [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ] )"
			}
			avance "Leyendo configuracion del usuario..."
			if [ catch { 
				set conf [mysqlsel $tmp_con "
					select valor
					from configuracion_local 
					where Usuario = '[::winix::obtiene_valor usuario Error]'
					and Variable = 'web_administrador'
				" flatlist] 
			} resultado ] {
				mensaje_log "LOCAL: $resultado" [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ] Configuracion
				return "Error 05: No pude cargar configuracion local de [::winix::obtiene_valor usuario Error]"
			}
			if {"$conf" != "Cierto"} {
				return "Este usuario no es administrador"
			}
			::winix::asigna_valor web_administrador Cierto Navegador

			::winix::consola_mensaje "[::thread::id] -> $tmp_con" 20
			catch { mysqlclose $tmp_con }
			::winix::consola_mensaje "[::thread::id] -> $tmp_con <=Cerrado" 20
			return ""
		}
		solo_valida {
			avance "Validando usuario..."
			if {"[::winix::obtiene_valor ssl Falso]" == "Cierto"} {
				if [ catch { set tmp_con [ mysqlconnect -host [::winix::obtiene_valor servidor_LAN localhost] \
								-user [::winix::obtiene_valor usuario Error] \
								-password [::winix::obtiene_valor clave] \
								-ssl True \
								-sslkey  [ ::winix::obtiene_valor sslkey ] \
								-sslcert [ ::winix::obtiene_valor sslcert ] \
								-sslca   [ ::winix::obtiene_valor sslca ] \
							] 
					} resultado ] {
					mensaje_log "ERROR: $resultado" Conexion LOCAL
					return "Error 01: Usuario, clave o servidor invalidos"
				}
			} else {
				if [ catch { set tmp_con [ mysqlconnect -host [::winix::obtiene_valor servidor_LAN localhost] \
								-user [::winix::obtiene_valor usuario Error] \
								-password [::winix::obtiene_valor clave] \
							] 
					} resultado ] {
					mensaje_log "ERROR: $resultado" Conexion LOCAL
					return "Error 01: Usuario, clave o servidor invalidos"
				}
			}
			
			if [ catch { mysqluse $tmp_con [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ] } resultado ] {
				mensaje_log "LOCAL: $resultado" [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ]
				return "Error 02: Revise configuracion del sistema. ( [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ] )"
			}    


			::winix::consola_mensaje "[::thread::id] -> $tmp_con" 20
			catch { mysqlclose $tmp_con }
			::winix::consola_mensaje "[::thread::id] -> $tmp_con <=Cerrado" 20
			return ""
		}
		solo_valida_usuario {
			avance "Validando usuario..."
			if {"[::winix::obtiene_valor ssl Falso]" == "Cierto"} {
				if [ catch { set tmp_con [ mysqlconnect -host [::winix::obtiene_valor servidor_LAN localhost] \
								-user $usuario \
								-password $clave \
								-ssl True \
								-sslkey  [ ::winix::obtiene_valor sslkey ] \
								-sslcert [ ::winix::obtiene_valor sslcert ] \
								-sslca   [ ::winix::obtiene_valor sslca ]
							] 
					} resultado ] {
					mensaje_log "ERROR: $resultado" Conexion LOCAL
					return "Error 01: Usuario, clave o servidor invalidos"
					puts "ERROR: $resultado"
				}
			} else {
				if [ catch { set tmp_con [ mysqlconnect -host [::winix::obtiene_valor servidor_LAN localhost] \
								-user $usuario \
								-password $clave \
							] 
					} resultado ] {
					mensaje_log "ERROR: $resultado" Conexion LOCAL
					return "Error 01: Usuario, clave o servidor invalidos"
					puts "ERROR: $resultado"
				}
			}
			
			if [ catch { mysqluse $tmp_con [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ] } resultado ] {
				mensaje_log "LOCAL: $resultado" [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ]
				return "Error 02: Revise configuracion del sistema. ( [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ] )"
			}    


			::winix::consola_mensaje "[::thread::id] -> $tmp_con" 20
			catch { mysqlclose $tmp_con }
			::winix::consola_mensaje "[::thread::id] -> $tmp_con <=Cerrado" 20
			return ""
		}
	}
}

# ------------------------------------------------
# Carga menu en base a los privilegios del usuario
# ------------------------------------------------

proc obtiene_menu_del_usuario {  { tipo_plataforma gui } { usuario usuario}  } {
	set menu_sistema ""
	set menu_dimmt ""

	if { "$usuario" == "usuario" } {
		set usuario [::winix::obtiene_valor $usuario Error]
	}
	debug "Obteniendo menu del usuario $usuario para la plataforma $tipo_plataforma"

	set menu_sistema [ ::winix::objeto_consulta consulta_express "
		select GP.Menu,P.Descripcion,lcase(P.Codigo),atajo,Nivel,Etapa 
			from <*empleados*> as E 
				left join <*catalogopuestos*> as CP on E.CodigoPuesto = CP.Codigo 
				left join <*grupos*> as G on CP.CodigoGrupo$tipo_plataforma = G.Codigo 
				left join <*gruposprogramas*> as GP on GP.CodigoGrupo = CP.CodigoGrupo$tipo_plataforma
				left join <*programas*> as P on GP.Programa = P.Codigo
				where E.usuario = '$usuario'
				and (Proyecto = 'BASEDIM' or Proyecto = '[::winix::obtiene_valor proyecto WINIX ]')
				and Etapa != 'Disponible'
				order by GP.Orden
	" flatlist]

	set menu_dimmt [ ::winix::objeto_consulta consulta_express "
		select GP.Menu,P.Descripcion,lcase(P.Codigo),atajo,Nivel,Etapa
		from <*empleados*> as E
		left join <*catalogopuestos*> as CP on E.CodigoPuesto = CP.Codigo
		left join <*grupos*> as G on CP.CodigoGrupo$tipo_plataforma = G.Codigo
		left join <*gruposprogramas*> as GP on GP.CodigoGrupo = CP.CodigoGrupo$tipo_plataforma
		left join <*entorno_trabajo*> as P on GP.Programa = P.Codigo
		where E.usuario = '$usuario'
		and Etapa != 'Disponible'
		order by GP.Orden
        " flatlist]

	::winix::consola_mensaje "$menu_sistema $menu_dimmt"
	debug "Menu del usuario $usuario  ---> $menu_sistema $menu_dimmt"

	::winix::asigna_valor menu "$menu_sistema $menu_dimmt" "Tablas del sistema" "empleados,catalogopuestos,grupos,gruposprogramas,entorno_trabajo"
}
