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

proc mensaje_error { mensaje {titulo "Errores graves que deberia usted saber"}  } {
	if { "[::winix::obtiene_valor debug false]" != "true"} { return }
	if { "[::winix::obtiene_valor debug_suave true]" == "true"} { return }
	if [winfo exist .mensaje_error] {
		for { set niv 1 } { $niv <= [info level] } { incr niv} {
			.mensaje_error.fr.texto insert end "[string repeat "  " $niv][lindex [info level $niv] 0]\n"
		}
		.mensaje_error.fr.texto insert end "$mensaje\n\n"
		wm deiconify .mensaje_error
		focus .mensaje_error
		return
	}
	toplevel .mensaje_error -bg red

	frame .mensaje_error.fr -bd 2 -relief sunken -bg red
	button .mensaje_error.fr.boton -text Aceptar \
		-command {
			grab release .mensaje_error
			destroy .mensaje_error
		}
	text .mensaje_error.fr.texto -fg black -bg white
	for { set niv 1 } { $niv <= [info level] } { incr niv} {
		.mensaje_error.fr.texto insert end "[string repeat "  " $niv][lindex [info level $niv] 0]\n"
	}
	.mensaje_error.fr.texto insert end "$mensaje\n\n"

	pack .mensaje_error.fr -expand true -fill both
	pack .mensaje_error.fr.boton -side bottom -expand true -fill x
	pack .mensaje_error.fr.texto -side left -expand true -fill both

	wm title .mensaje_error "$titulo"
	wm protocol  .mensaje_error WM_DELETE_WINDOW "
		grab release .mensaje_error
		destroy .mensaje_error
	"

	centrar_pantalla .mensaje_error

	wm deiconify .mensaje_error
	focus .mensaje_error.fr.boton
}

#Maximiza una ventana
proc maximizar_pantalla { top } {
    global tcl_platform
    
    if {[string equal $tcl_platform(platform) windows]} {
        wm state $top zoomed
    } else  {
#        pack propagate $top 0
#        update idletasks
#        wm geometry $top +0+0
#        wm minsize $top [winfo screenwidth .] [winfo screenheight .]
    }
    
    wm deiconify $top
}

# Centra la pantalla 'top'
proc centrar_pantalla { top } {
    catch {
        after idle [format {
            update idletasks
            set win %s
            set xmax [winfo screenwidth $win]
            set ymax [winfo screenheight $win]
            set x0 [expr ($xmax - [winfo reqwidth $win] ) / 2]
            set y0 [expr ($ymax - [winfo reqheight $win]) / 2 - 25]
            wm geometry $win "+$x0+$y0"
        } $top]
    }
}

proc tomar_foco_pantalla { top } {
    wm deiconify $top
}

# -------------------------------------------------------
# Envia mensaje grave, y espera para terminar el programa
# -------------------------------------------------------
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

        toplevel .mensaje
        wm geometry .mensaje 500x500
        wm title .mensaje "ATENCION!"
        wm protocol .mensaje WM_DELETE_WINDOW {destroy .mensaje}
        wm geometry .mensaje +100+200

        frame .mensaje.f0 -width 500 -height 150 -bg [::winix::obtiene_valor color_fondo white]
        frame .mensaje.f0.f1 -width 500 -height 110 -bg [::winix::obtiene_valor color_fondo white]
        text .mensaje.f0.f1.texto -bg [::winix::obtiene_valor color_fondo white] -font { Helvetica -14 bold } \
		-yscrollcommand {.mensaje.f0.f1.sc set}
	scrollbar .mensaje.f0.f1.sc -command {.mensaje.f0.f1.texto yview } -orient vertical
        frame .mensaje.f0.f2 -width 500 -height 10 -bg [::winix::obtiene_valor color_fondo white]
        frame .mensaje.f0.f3 -width 500 -height 30 -bg [::winix::obtiene_valor color_fondo white]
        button .mensaje.f0.f3.but31 -text OK -width 8 -command { termina } -bg [::winix::obtiene_valor color_boton #6699cc]

        pack .mensaje.f0 -fill both -expand yes
        pack .mensaje.f0.f1 -fill both -expand yes 
        pack .mensaje.f0.f2 -fill both
        pack .mensaje.f0.f3 -fill both
        pack .mensaje.f0.f1.texto -pady 10 -padx 10 -expand yes -fill both -side left
	pack .mensaje.f0.f1.sc -expand yes -fill y
        pack .mensaje.f0.f3.but31 -pady 5

        bell
        bell

	.mensaje.f0.f1.texto insert end "$problema \n \nERROR:  $var_texto"
	
        bind .mensaje.f0.f3.but31 <Return> { termina }
        bind .mensaje.f0.f3.but31 <KP_Enter> { termina }

	centrar_pantalla .mensaje

        grab .mensaje
        focus .mensaje.f0.f3.but31
        tkwait window .mensaje
    }
}

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

proc complementa_configuracion { } {
    if {"[::winix::obtiene_valor tile Falso]" == "Cierto"} {
	if [ catch { package require tile } resultado ] {
		::winix::asigna_valor tile Falso Cargador"Error cargando Package tile $resultado"
	}
    }

    if {"[::winix::obtiene_valor tile Falso]" == "Cierto"} {
	::ttk::setTheme [::winix::obtiene_valor tile_tema alt]
    }

    if { "[::winix::obtiene_valor tile Falso]" == "Cierto" } {
	foreach { color objeto atributo} {
		color_boton 				"" 	-foreground
		color_menus_texto 				"" 	-foreground
		color_menus_texto_seleccionado 			"" 	-selectforeground
		color_programa_captura_texto 			TEntry 	-foreground
		color_programa_busqueda_texto 			TEntry 	-foreground
		color_programa_busqueda_texto_seleccionado 	TEntry 	-foreground
		color_programa_busqueda_texto_titulo	 	"" 	-foreground
		color_programa_texto 				"" 	-foreground
		color_editor_texto 				TEntry 	-foreground
		color_programa_cuadricula_titulo_texto 		"" 	-foreground
		color_programa_cuadricula_texto 		TEntry 	-foreground
		color_programa_cuadricula_texto_noeditable 	TEntry 	-foreground
		color_programa_arbol_texto 			TEntry 	-foreground

		color_menus_fondo 				"" 	-background
		color_fondo 				"" 	-background
		color_menus_fondo_seleccionado 			"" 	-selectbackground
		color_programa_captura_fondo 			TEntry 	-fieldbackground
		color_programa_busqueda_fondo 			TEntry 	-fieldbackground
		color_programa_busqueda_fondo_seleccionado 	TEntry 	-fieldbackground
		color_programa_busqueda_fondo_titulo	 	"" 	-background
		color_programa_fondo 				"" 	-background
		color_editor_fondo 				TEntry 	-fieldbackground
		color_programa_cuadricula_titulo_fondo 		"" 	-background
		color_programa_cuadricula_fondo 		TEntry 	-fieldbackground
		color_programa_cuadricula_fondo_noeditable 	TEntry 	-fieldbackground
		color_programa_arbol_fondo 			TEntry 	-fieldbackground

	} {
		set temporal [ ttk::style lookup $objeto $atributo ]
		if {"$temporal" == ""} {
			debug "No se pudo cargar color $color desde el tema tile con objeto $objeto y atributo $atributo" 4
		} else {
			::winix::asigna_valor $color $temporal Cargador "Extraccion de valores de tile"
		}
	}
	
    }
    catch {
    	package require tablelist_tile
    }

    return ""
}

# -------------------------------------------------------------------------------
# Pasa a modo diferido cuando hay problemas para conectarse al servidor principal
# -------------------------------------------------------------------------------

proc modo_diferido { {buffer ""} } {

	debug "Cambiando a modo diferido debido a $buffer"

	::winix::asigna_valor desconectado 	1 			Evento "Fallo algo $buffer"
	::winix::asigna_valor actualizado  	0 			Evento "Fallo algo $buffer"
	::winix::asigna_valor estado_conexion 	"Proceso Diferido"	Evento "Fallo algo $buffer"

	if [winfo exists .menu] {
		if [::winix::obtiene_valor es_sucursal 0] {
			wm title .menu "[::winix::obtiene_valor sistema {Proyecto Winix}] - Sucursal [::winix::obtiene_valor sucursal Sucursal] ([::winix::obtiene_valor estado_conexion {Proceso Diferido} ])"
		} else {
			wm title .menu "[::winix::obtiene_valor sistema {Proyecto Winix}] - [::winix::obtiene_valor sucursal Matriz] ([::winix::obtiene_valor estado_conexion {Proceso Diferido}])"
		}
	}
}

proc esta_diferido { } {
	if {"[::winix::obtiene_valor estado_conexion {Proceso Diferido}]" == "Proceso Diferido" } {
		return 1
	} else {
		return 0
	}
}

proc avance { mensaje_avance { magnitud 0 } } {
	.login.avance configure -text $mensaje_avance
	debug $mensaje_avance
	update
}

# ------------------------------------------------
# Carga menu en base a los privilegios del usuario
# ------------------------------------------------

# ------------------------
# Arma el menu del sistema
# ------------------------

proc armar_menu_pantalla { lista_menu ventana } {
    if {$ventana == "."} {
	        set mnu [menu .menu_principal \
				-background [::winix::obtiene_valor color_menus_fondo #6699cc] \
				-tearoff 0 \
				-activebackgroun [::winix::obtiene_valor color_menus_fondo_seleccionado white] \
				-foreground [::winix::obtiene_valor color_menus_texto white] \
				-activeforegroun [::winix::obtiene_valor color_menus_texto_seleccionado #6699cc] \
				-font [::winix::obtiene_valor letra_menus {monospace 16 normal} ] ]
    } else  {
        	set mnu [menu $ventana.menu_principal 			-background [::winix::obtiene_valor color_menus_fondo #6699cc] \
				-tearoff 0 \
				-activebackgroun [::winix::obtiene_valor color_menus_fondo_seleccionado white] \
				-foreground [::winix::obtiene_valor color_menus_texto white] \
				-activeforegroun [::winix::obtiene_valor color_menus_texto_seleccionado #6699cc] \
				-font [::winix::obtiene_valor letra_menus {monospace 16 normal} ] ]

    }

    $ventana configure -menu $mnu

    foreach { linea } $lista_menu {
        set nombre_menu [lindex $linea 0]
        set tipo [lindex $linea 1]
        set nombre [lindex $linea 2]
        set args [lrange $linea 3 end]

        set dirmenu "$mnu"
        foreach {nombre_submenu} [split $nombre_menu /] {
	    set letra [string first "¬" $nombre_submenu]

    	    if {$letra > -1 } {
		set nombre_submenu [string replace $nombre_submenu $letra $letra ]
	    }

            set submenu [join $nombre_submenu _]
            set dirmenu "$dirmenu.m$submenu"

            if {![winfo exists $dirmenu]} {
                set menu_anterior [winfo parent [menu $dirmenu -tearoff 0]]
                $menu_anterior add cascade \
			-label $nombre_submenu \
			-menu $dirmenu \
			-underline $letra \
			-background [::winix::obtiene_valor color_menus_fondo #6699cc] \
			-activebackgroun [::winix::obtiene_valor color_menus_fondo_seleccionado white] \
			-foreground [::winix::obtiene_valor color_menus_texto white] \
			-activeforegroun [::winix::obtiene_valor color_menus_texto_seleccionado #6699cc] \
			-font [::winix::obtiene_valor letra_menus {monospace 16 normal} ]
            }
        }

        agregar_linea_menu $dirmenu $tipo $nombre $args

    }
}

proc agregar_linea_menu {mnu tipo nombre args} {
    set letra -1
    set combinacion ""
    set color_fondo [::winix::obtiene_valor color_menus_fondo #6699cc]
    set color_letra [::winix::obtiene_valor color_menus_texto white]

    set comando ""
    
    foreach {opcion valor} [lindex $args 0] {
        switch -- $opcion {
            -Letra { set letra $valor }
            -Combinacion { set combinacion $valor }
            -ColorFondo { set color_fondo $valor }
            -ColorLetra { set color_letra $valor }
            -Comando { set comando $valor }
        }
    }
    
    switch -- $tipo {
        comando {
            $mnu add command -label $nombre -underline $letra -accelerator $combinacion \
                    -background $color_fondo -foreground $color_letra -command $comando
        }
        separador {
            $mnu add separator
        }
        seleccion {
            $mnu add checkbutton -label $nombre -underline $letra -accelerator $combinacion \
                    -background $color_fondo -foreground $color_letra -command $comando
        }
        opcion {
            $mnu add radiobutton -label $nombre -underline $letra -accelerator $combinacion \
                    -background $color_fondo -foreground $color_letra -command $comando
        }
    }
}

proc arma_menu { } {
    debug "Armando menu"

    if {[winfo exists .menu ]} {
        tomar_foco_pantalla .menu
        return
    }

    if {"[::winix::obtiene_valor ventana_menus_formato completa]" == "completa"} {
	catch {
		image create photo foto -file [::winix::obtiene_valor directorio . ]/imagenes/[::winix::obtiene_valor fondo fondo.jpg]
	}
    }

    toplevel .menu -background [::winix::obtiene_valor color_fondo white]
    bind .menu <F1> "::winix::consulta_ayuda .menu"
    bind .menu <F10> "::winix::edita_ayuda .menu"
    wm protocol .menu WM_DELETE_WINDOW termina
    wm withdraw .menu
    
    if {"[::winix::obtiene_valor ventana_menus_formato completa]" == "autonoma"} {
        ::winix::asigna_valor width [winfo screenwidth  . ] Cargador "winfo screenwidth"
    	   wm overrideredirect .menu 1
    }
    
    if {"[::winix::obtiene_valor ventana_menus_formato completa]" == "compacta"} {
        ::winix::asigna_valor width [winfo screenwidth  . ] Cargador "winfo screenwidth"
    }
    
    frame .menu.herramientas -background [::winix::obtiene_valor color_programa_fondo #6699cc] -relief sunken
    if {"[::winix::obtiene_valor ventana_menus_formato completa]" == "completa"} {
    	frame .menu.frame -background [::winix::obtiene_valor color_programa_fondo #6699cc]  -height 600 -width 800
    	catch {
			label .menu.frame.imagen -image foto -anchor center -background [::winix::obtiene_valor color__toplevel_fondo white]
		}
    }
    
    label .menu.usuario -background [::winix::obtiene_valor color_programa_fondo #6699cc] -foreground [::winix::obtiene_valor color_programa_texto white]\
		-text "Usuario [::winix::obtiene_valor usuario Error]:[::winix::obtiene_valor nombre_usuario desconocido]" -anchor e -relief sunken -bd 1
    label .menu.version -background [::winix::obtiene_valor color_programa_fondo #6699cc] -foreground [::winix::obtiene_valor color_programa_texto white]\
		-text "[::winix::obtiene_valor version {Versión 1.0}]" -anchor center -relief sunken -bd 1
    label .menu.mensajes -background [::winix::obtiene_valor color_programa_fondo #6699cc] -foreground [::winix::obtiene_valor color_programa_texto white]\
		-text "Mensajes:" -anchor e -bd 1
    label .menu.nmensajes -background [::winix::obtiene_valor color_programa_fondo #6699cc] -foreground [::winix::obtiene_valor color_programa_texto white]\
		-textvar ::conf(mensajes) -anchor e  -relief sunken -bd 1
    label .menu.servidorl -background [::winix::obtiene_valor color_programa_fondo #6699cc] -foreground [::winix::obtiene_valor color_programa_texto white]\
		-text "LAN" -anchor e -bd 1
    label .menu.dservidorl -background [::winix::obtiene_valor color_programa_fondo #6699cc] -foreground [::winix::obtiene_valor color_programa_texto white]\
		-textvar ::conf(servidor_LAN) -anchor e -bd 1
	if {"[::winix::obtiene_valor dedicado Cierto]" != "Cierto"} {
		label .menu.servidorw -background [::winix::obtiene_valor color_programa_fondo #6699cc] -foreground [::winix::obtiene_valor color_programa_texto white]\
				-text "WAN" -anchor e
		label .menu.dservidorw -background [::winix::obtiene_valor color_programa_fondo #6699cc] -foreground [::winix::obtiene_valor color_programa_texto white]\
				-textvar ::conf(servidor_WAN) -anchor e  -relief sunken
	}
    label .menu.bd -background [::winix::obtiene_valor color_programa_fondo #6699cc] -foreground [::winix::obtiene_valor color_programa_texto white]\
		-text "DB" -anchor e  -relief sunken -bd 1
    label .menu.nbd -background [::winix::obtiene_valor color_programa_fondo #6699cc] -foreground [::winix::obtiene_valor color_programa_texto white]\
		-textvar ::conf(db) -anchor e  -relief sunken -bd 1
    label .menu.relleno	-background [::winix::obtiene_valor color_programa_fondo #6699cc] -foreground [::winix::obtiene_valor color_programa_texto white]\
		-bd 1
	label .menu.empresa -background [::winix::obtiene_valor color_programa_fondo #6699cc] -foreground [::winix::obtiene_valor color_programa_texto white]\
		-text "Empresa" -anchor e
	label .menu.nempresa -background [::winix::obtiene_valor color_programa_fondo #6699cc] -foreground [::winix::obtiene_valor color_programa_texto white]\
		-textvar ::conf(nombre_empresa) -anchor e  -relief sunken

	pack .menu.herramientas -in .menu -side top -expand false -fill x
    if {"[::winix::obtiene_valor ventana_menus_formato completa]" == "completa"} {
    	pack .menu.frame -in .menu -expand 1 -fill both
	catch {
    		pack .menu.frame.imagen -in .menu.frame -side top -expand 1 -fill both
	}
    }
    
    pack .menu.usuario 	-expand false -fill x -side right
    pack .menu.version 	-expand false -fill x -side right 
    pack .menu.nbd 	-expand false -fill x -side right 
    pack .menu.bd 	-expand false -fill x -side right
	if {"[::winix::obtiene_valor dedicado Cierto]" != "Cierto"} {
		pack .menu.dservidorw 	-expand false -fill x -side right
		pack .menu.servidorw 	-expand false -fill x -side right
	}
    pack .menu.dservidorl 	-expand false -fill x -side right 
    pack .menu.servidorl 	-expand false -fill x -side right
	pack .menu.nempresa 	-expand false -fill x -side right
	pack .menu.empresa 	-expand false -fill x -side right
    pack .menu.mensajes 	-expand false -fill x -side left 
    pack .menu.nmensajes 	-expand false -fill x -side left
    pack .menu.relleno 	-expand false -fill x -side top
    # update idletasks
    
    menu .menu.principal 	-background [::winix::obtiene_valor color_menus_fondo #6699cc] \
			-tearoff 0 \
			-activebackgroun [::winix::obtiene_valor color_menus_fondo_seleccionado white] \
			-foreground [::winix::obtiene_valor color_menus_texto white] \
			-activeforegroun [::winix::obtiene_valor color_menus_texto_seleccionado #6699cc] \
			-font [::winix::obtiene_valor letra_menus {monospace 16 normal} ] 

    # set menu_principal [list] ;# Variable que hace el menu principal
    foreach { grupo opcion programa atajo nivel etapa } [::winix::obtiene_valor menu "" ] {
        
    	switch $etapa {
    		nombrado {
    			set color_fondo black
    			set color_texto gray
    			set color_texto_seleccionado $color_texto
    		}
    		objetos {
    			set color_fondo gray
    			set color_texto black
    			set color_texto_seleccionado $color_texto
    		}
    		objetos_terminados {
    			set color_fondo gray
    			set color_texto yellow
    			set color_texto_seleccionado $color_texto
    		}
    		procesos {
    			set color_fondo blue
    			set color_texto black
    			set color_texto_seleccionado $color_texto
    		}
    		procesos_terminados {
    			set color_fondo blue
    			set color_texto yellow
    			set color_texto_seleccionado $color_texto
    		}
    		terminado {
    			set color_fondo #b5caec
    			set color_texto yellow
    			set color_texto_seleccionado $color_texto
    		}
    		terminado_impreso {
    			set color_fondo #b5caec
    			set color_texto yellow
    			set color_texto_seleccionado $color_texto
    		}
    		control_calidad {
    			set color_fondo #b5caec
    			set color_texto red
    			set color_texto_seleccionado $color_texto
    		}
    		cliente {
    			set color_fondo [::winix::obtiene_valor color_menus_fondo #6699cc]
    			set color_texto [::winix::obtiene_valor color_menus_texto white]
    			set color_texto_seleccionado $color_texto
    		}
    		reajustes {
    			set color_fondo red
    			set color_texto yellow
    			set color_texto_seleccionado $color_texto
    		}
    		produccion {
    			set color_fondo [::winix::obtiene_valor color_menus_fondo #6699cc]
    			set color_texto [::winix::obtiene_valor color_menus_texto white]
    			set color_texto_seleccionado [::winix::obtiene_valor color_menus_texto_seleccionado #6699cc]
    		}
    	}

        lappend menu_principal "[list $grupo] comando [list $opcion]
            -Comando {cargar $programa $nivel}
            -Letra $atajo
            -ColorFondo $color_fondo
            -ColorLetra $color_texto
            -ColorFondoActivo [::winix::obtiene_valor color_menus_fondo_seleccionado white]
            -ColorLetraActivo $color_texto_seleccionado"

        debug "Programa $programa tiene nivel $nivel" 20
	set ::niveles($programa) $nivel
    }

    lappend menu_principal "{} comando Salir -Comando termina -Letra 0"
    armar_menu_pantalla $menu_principal .menu

    bind .menu <Key-Escape> termina

    if { "[::winix::obtiene_valor width [winfo screenwidth . ] ]" == "automatico"} {
    	::winix::asigna_valor width [winfo screenwidth  . ] cargador automatico

    }
    if { "[::winix::obtiene_valor height [winfo screenheight . ] ]" == "automatico"} {
    	::winix::asigna_valor height [winfo screenheight  . ] cargador automatico
    }
    
    set x [expr { ( [winfo screenwidth  .] - [::winix::obtiene_valor width [winfo screenwidth . ] ]  ) / 2 }]
    set y [expr { ( [winfo screenheight .] - [::winix::obtiene_valor height [winfo screenheight . ] ] ) / 2 }]
    
    wm deiconify .menu
    if {"[::winix::obtiene_valor ventana_menus_formato completa]" == "completa"} {
        wm geometry .menu [::winix::obtiene_valor width [winfo screenwidth . ] ]x[::winix::obtiene_valor height [winfo screenheight . ] ]+0+0  
    } else {
        wm geometry .menu [::winix::obtiene_valor width [winfo screenwidth . ] ]x20+0+0    
    }
    if [::winix::obtiene_valor es_sucursal 0 ] {
	wm title .menu "[::winix::obtiene_valor sistema { Proyecto Winix } ] - Sucursal [::winix::obtiene_valor sucursal sucursal] ([::winix::obtiene_valor estado_conexion desconectado])"
    } else {
	wm title .menu "[::winix::obtiene_valor sistema { Proyecto Winix } ] - [::winix::obtiene_valor sucursal Matriz] ([::winix::obtiene_valor estado_conexion desconectado])"
    }

#    update idletasks

    wm withdraw .

#    update

    focus .menu

    ::winix::asigna_valor ventana_posicion_y 0

    arma_barra_herramientas

    if [::winix::existe_variable instancia_inicial ] {
	cargar [::winix::obtiene_valor instancia_inicial] [::winix::obtiene_niveles [::winix::obtiene_valor instancia_inicial] Consulta ]
    }
}

# ---------------------------
# Carga programa seleccionado
# ---------------------------

proc cargar { programa nivel {proceso_adjunto ""} } {
	global tipo_programa

	debug "Cargando programa $programa con opcion [::winix::obtiene_valor programas bd ] nivel $nivel"

	switch [::winix::obtiene_valor programas bd ] {
		bd {
			set nivel [::winix::obtiene_nivel $programa ]
			set programa [string tolower $programa]

			set ::winix_generales(base_datos) dimdb
      			set reg [mysqlsel [::winix::obtiene_valor base_LAN ] "
               			select Programa,TipoPrograma,Descripcion
               			from [::winix::obtiene_valor dimdb Winix_MT].entorno_trabajo
               			where Codigo = '$programa'
					and Etapa != 'Disponible'
			" -flatlist ]                        

			if {$reg == ""} {
				set ::winix_generales(base_datos)  sistemasdb

				set reg [mysqlsel [::winix::obtiene_valor base_LAN ] "
					select Programa,TipoPrograma,Descripcion from [::winix::obtiene_valor sistemasdb [::winix::obtiene_valor nombre_base_cargador winix]_sistema ].programas
					where Codigo = '$programa' 
						and (Proyecto = 'BASEDIM' or Proyecto = '[::winix::obtiene_valor proyecto WINIX ]')
						and Etapa != 'Disponible'
                		" -flatlist ]
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
		foreach consecutivo  { 0 1 2 3 4 } {
			if {[winfo exists ".$programa$consecutivo"]} {
			} else {
				set codigo_instancia "$programa$consecutivo"
			}
		}
		if {"$codigo_instancia" == ""} {
		} else {
			regsub -all {espacio_de_nombre} $codigo $codigo_instancia codigo_destino
			set codigo $codigo_destino
			regsub -all {nombre_de_instancia_original} $codigo $programa codigo_destino
			set codigo $codigo_destino
		}
	} else {
		set codigo_instancia $programa
		if {[winfo exists ".$programa"]} {
			if {$tipo_programa == "Programa"} {
				destroy .$programa
			}
		}
		catch {
			namespace delete ::${programa}
		}
	}

	set ::programas($programa) $tipo_programa
	set ::niveles($programa)   $nivel
	
	eval $codigo

	set programa $codigo_instancia

	if {[winfo exists ".$programa"]} {
		if {$::programas($programa) == "Instancia" || $::programas($programa) == "Multi-Instancia" } {
			::${programa}::inicia
			if [winfo exist .$programa] {
				bind ."::${programa}" <F12> "debug \"Ejecutando el programa $programa\" "
			}
		} else {
			::${programa}::${programa}scr muestra
		}
	} else {
		::${programa}::inicia
		if [winfo exist .$programa] {
			bind .$programa <F12> "debug \"Ejecutando el programa $programa\" "
		}
	}

	update 

	if {"$proceso_adjunto" != "" } {
		eval $proceso_adjunto
	}
}

proc cargar_de_memoria { codigo programa tipo_programa nivel} {

	if {$tipo_programa == "Multi-Instancia"} {
		return
	}

	if {[winfo exists ".$codigo"]} {
		if {$tipo_programa == "Programa"} {
			destroy .$programa
		}
	}
	catch {
		namespace delete ::${codigo}
	}

	set ::niveles($codigo) $nivel

	eval $programa

	if {$tipo_programa == "Instancia"} {
		::${codigo}::inicia
		if [winfo exist .$codigo] {
			bind .$codigo <F12> "debug \"Ejecutando el programa $codigo\" "
		} else {
			::${codigo}::${codigo}scr muestra
		}
	}
}

proc arma_barra_herramientas {  { tipo_plataforma gui } } {
	# La barra comenzo a existir en la Version 2.0, antes no existian los campos requeridos
	# No queremos tronar por falta de informacion en la tabla gruposprogramas
	if { [::winix::variable_local version_requerida_dim_mt 1.0] < 2.0 } {
		return
	}
	debug "Obteniendo barra de herramienta"
	if [ catch { set barra_sistema [mysqlsel [::winix::obtiene_valor base_LAN ] "
		select lcase(P.Codigo),ImagenHerramienta,PosicionHerramienta,Nivel
			from empleados as E 
				left join catalogopuestos as CP on E.CodigoPuesto = CP.Codigo 
				left join grupos as G on CP.CodigoGrupo$tipo_plataforma = G.Codigo 
				left join gruposprogramas as GP on GP.CodigoGrupo = CP.CodigoGrupo$tipo_plataforma 
				left join [::winix::obtiene_valor sistemasdb [::winix::obtiene_valor nombre_base_cargador winix]_sistema ].programas as P on GP.Programa = P.Codigo
				where E.usuario = '[::winix::obtiene_valor usuario Error]'
				and (Proyecto = 'BASEDIM' or Proyecto = '[::winix::obtiene_valor proyecto WINIX ]')
				and Etapa != 'Disponible' and GP.PosicionHerramienta != 0
				order by GP.PosicionHerramienta
		" -flatlist] } resultado ] {
		mensaje_log "LOCAL: $resultado" [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ] Configuracion
		problemas "Error 08: No se pudo recuperar menu para este usuario." $resultado
    	}

    	if [ catch { set barra_dimmt [mysqlsel [::winix::obtiene_valor base_LAN ] "
	        select lcase(P.Codigo),ImagenHerramienta,PosicionHerramienta,Nivel
		        from empleados as E
	        		left join catalogopuestos as CP on E.CodigoPuesto = CP.Codigo
	        		left join grupos as G on CP.CodigoGrupo$tipo_plataforma  = G.Codigo
	        		left join gruposprogramas as GP on GP.CodigoGrupo = CP.CodigoGrupo$tipo_plataforma 
	        		left join [::winix::obtiene_valor dimdb Winix_MT].entorno_trabajo as P on GP.Programa = P.Codigo
	        		where E.usuario = '[::winix::obtiene_valor usuario Error]'
            			and Etapa != 'Disponible' and GP.PosicionHerramienta != 0
            			order by GP.PosicionHerramienta
        	" -flatlist] } resultado ] {
        	mensaje_log "LOCAL: $resultado" [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ] Configuracion
        	problemas "Error 09: No se pudo recuperar menu para este usuario." $resultado
    	}

	# armamos primero la barra de Winix, que puede ser sustituidas posiciones por la barra del sistema

	foreach {codigo imagen posicion nivel} $barra_dimmt {
		set barra_herramientas_codigo($posicion) $codigo
		set barra_herramientas_imagen($posicion) $imagen
		set barra_herramientas_nivel($posicion)  $nivel
	}
	foreach {codigo imagen posicion nivel} $barra_sistema {
		set barra_herramientas_codigo($posicion) $codigo
		set barra_herramientas_imagen($posicion) $imagen
		set barra_herramientas_nivel($posicion)  $nivel
	}

	#tenemos nuesta barra, la montamos en su lugar
	foreach posicion [lsort [array names barra_herramientas_codigo]] {
		if {"[::winix::variable_local tile Falso]" == "Cierto"} {
			ttk::button .menu.herramientas.boton$posicion \
				-command [list cargar $barra_herramientas_codigo($posicion) $barra_herramientas_nivel($posicion)] \
				-image [::winix::imagen $barra_herramientas_imagen($posicion)] \
				-compound center -style THerramienta
		} else {
			button .menu.herramientas.boton$posicion \
				-command [list cargar $barra_herramientas_codigo($posicion) $barra_herramientas_nivel($posicion)] \
				-image [::winix::imagen $barra_herramientas_imagen($posicion)]\
				-compound center -relief flat -background [::winix::obtiene_valor color__toplevel_fondo white]
		}
		catch {
		pack .menu.herramientas.boton$posicion -side left -expand false -fill none
		}
	}
	if {"[::winix::variable_local tile Falso]" == "Cierto"} {
		ttk::button .menu.herramientas.salida \
			-command termina \
			-image [::winix::imagen salida] \
			-compound center -style THerramienta
	} else {
		button .menu.herramientas.salida \
			-command termina \
			-image [::winix::imagen salida]\
			-compound center -relief flat -background [::winix::obtiene_valor color__toplevel_fondo white]
	}
	catch {
	pack .menu.herramientas.salida -side right -expand false -fill none
	}
}
# ------------------------------
# Ventana de entrada del sistema
# ------------------------------

source "[::winix::obtiene_valor directorio .]/entrada.tcl"

# ------------------------------
# Login del sistema
# ------------------------------

proc login { } {
	wm title .login "Ingrese su Usuario y Clave"
#	wm overrideredirect .login 1

	set ::intentos 0

	bind .login <Tab> break
	
	bind .login <Escape> {
		destroy .
		exit
	}

	bind .login.usuario.entry <Return> {
		focus .login.clave.entry
	}

	bind .login.clave.entry <Return> {
		::winix::asigna_valor usuario $::conf(usuario) GUI Capturado
		::winix::asigna_valor clave $::conf(clave) GUI Capturado
		.login.mensaje configure -text ""
		if [ingresar] {
			avance ""
			incr ::intentos
			if {$intentos > 3} {
				problemas "Saliendo del programa" "Ha excedido el limite de intentos"
			}
			focus .login.usuario.entry
        	} else {
			destroy .login
			#maximizar_pantalla .menu
		}
	}

	wm iconify .login
	wm withdraw .

	wm deiconify .login
	focus .login.usuario.entry

}

proc ingresar { } {
	global tcl_platform
	wm title .login "Ingresando al sistema..."

#	if {[string equal $tcl_platform(platform) windows]} {#
#	} else {
#		tk scaling 1
#	}

	bind all <Control-l> { debug "" 0}
	bind all <Control-k> {
		::winix::lista_variables
	}

	set resultado [obtiene_configuracion]

	if {"$resultado" == ""} {
		avance "Cargando sistema principal..."
		cargar_catalogo_programas
		cargar_rutinas
		cargar_clases
		cargar_procesos
		cargar_configuraciones
		avance "Leyendo menus del usuario..."
		obtiene_menu_del_usuario gui
		avance "Preparando menu del usuario..."
		arma_menu

		wm withdraw .
		wm withdraw .login
		return 0
	} else {
		if {[string first "Access denied" $resultado] > 0 } {
			.login.mensaje configure -text "Usuario o Clave incorrectos"
		} else {
			if {[string first "connect" $resultado] > 0 } {
				.login.mensaje configure -text "Problemas de comunicacion con servidor"
			} else {
				.login.mensaje configure -text $resultado
			}
		}
		return 1
	}

	wm withdraw .
}

proc termina { } {
	catch {
		mysqlclose [::winix::obtiene_valor base_LAN ]
	}
	catch {
		mysqlclose [::winix::obtiene_valor base_WAN ]
	}

	::exit
}

proc tronar { resultado fase {usuario sin_usuario } { codigo "" } } {
	if {"[::winix::obtiene_valor debug false]" == "true"} {
		debug "Por culpa de $usuario, $codigo tenemos un " -1
		debug "Errores al cargar $fase : $resultado" -1
		wm deiconify .debug
		focus .debug.txt
		.debug.txt see end
	} else {
		problemas "Error 10: grave del sistema" $resultado
	}
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

	if {[winfo exists ".debug"]} {
		if {$nivel == 0} { 
			.debug.txt delete 1.0 end 
		}
	} else {
		set width [winfo screenwidth  .]
		set height [winfo screenheight  .]

		toplevel .debug
		bind .debug <F1> "::winix::consulta_ayuda .debug"
		bind .debug <F10> "::winix::edita_ayuda .debug"
		checkbutton .debug.desplaza -variable ::debug(desplaza) -text "Auto Desplazamiento"
		text .debug.txt -yscrollcommand {.debug.scr set}
		scrollbar .debug.scr -command {.debug.txt yview}
		pack .debug.desplaza -side top -expand false -fill none
		pack .debug.scr -side right -fill y -expand false
		pack .debug.txt -expand true -fill both
		set x [expr { ( [winfo screenwidth  .] - $width  ) / 2 }]
		set y [expr { ( [winfo screenheight .] - $height ) / 2 }]

		wm geometry .debug ${width}x${height}+${x}+${y}
		wm title .debug "Ventana de debug del sistema"

		update

		wm iconify .debug

		for { set l -1 } { $l <= [::winix::obtiene_valor nivel 5 ] } { incr l } {
			if [info exists ::debugcolorf($l)] {
			} else {
				set ::debugcolorf($l) $::debugcolorf(0)
				set ::debugcolorl($l) $::debugcolorl(0)
			}
			.debug.txt tag configure tag$l \
				-background $::debugcolorf($l) \
				-foreground $::debugcolorl($l) \
		}
	}

	.debug.txt insert end "$mensaje\n" tag$nivel
	if {[::winix::obtiene_valor debug_consola Cierto ] == "Cierto"} {
		puts ":> $mensaje"
	}

	if {$::debug(desplaza)} {
		.debug.txt see end
	}
	if {$nivel == -1} {
		mensaje_error "$mensaje"
	}
}

proc modo_diferido { {buffer ""} } {

	debug "Cambiando a modo diferido debido a $buffer"

	::winix::asigna_valor desconectado 	1 			Evento "Fallo algo $buffer"
	::winix::asigna_valor actualizado  	0 			Evento "Fallo algo $buffer"
	::winix::asigna_valor estado_conexion 	"Proceso Diferido"	Evento "Fallo algo $buffer"

	if [winfo exists .menu] {
		if [::winix::obtiene_valor es_sucursal 0] {
			wm title .menu "[::winix::obtiene_valor sistema {Proyecto Winix}] - Sucursal [::winix::obtiene_valor sucursal Sucursal] ([::winix::obtiene_valor estado_conexion {Proceso Diferido} ])"
		} else {
			wm title .menu "[::winix::obtiene_valor sistema {Proyecto Winix}] - [::winix::obtiene_valor sucursal Matriz] ([::winix::obtiene_valor estado_conexion {Proceso Diferido}])"
		}
	}
}

# ------------------------------------
# Carga rutinas auxiliares del sistema de base de datos
# ------------------------------------

proc cargar_rutinas_bd { } {
	debug "Cargando rutinas internas con opcion [::winix::obtiene_valor programas bd ]"
	avance "Cargando sistema principal... Rutinas."

	set ::winix_generales(base_datos) sistemasdb
	set programas [mysqlsel [::winix::obtiene_valor base_LAN ] "
        select Codigo,Programa,UsuarioModificacion,Descripcion from [::winix::obtiene_valor sistemasdb [::winix::obtiene_valor nombre_base_cargador winix]_sistema ].programas
		where   TipoPrograma = 'Rutinas' 
				and (Proyecto = 'BASEDIM' or Proyecto = '[::winix::obtiene_valor proyecto WINIX ]')
	" -flatlist ]

	foreach {codigo programa usuario descripcion} $programas {
		set ::winix_generales(codigo) $codigo
		set ::winix_generales(descripcion) $descripcion
		debug "Cargando $codigo modificado por $usuario .- $descripcion" 4
		debug $programa 25
		if [ catch { eval $programa } resultado ] {
			tronar "$resultado - $::errorInfo" "rutinas sistema" $usuario $codigo
		}
	}

	avance "Cargando sistema principal... Rutinas DIM-MT."
	# CARGANDO RUTINAS DE LA TABLA DIM_MT
	set ::winix_generales(base_datos) dimdb
	set programas [mysqlsel [::winix::obtiene_valor base_LAN ] "
        	select Codigo,Programa,UsuarioModificacion,Descripcion from [::winix::obtiene_valor dimdb Winix_MT].entorno_trabajo
        	where   TipoPrograma = 'Rutinas' order by Codigo
	" -flatlist ]
    
	foreach {codigo programa usuario descripcion} $programas {
		set ::winix_generales(codigo) $codigo
		set ::winix_generales(descripcion) $descripcion
	        debug "Cargando $codigo modificado por $usuario .- $descripcion" 4
	        debug $programa 25
	        if [ catch { eval $programa } resultado ] {
			tronar "$resultado - $::errorInfo" "rutinas basedim" $usuario $codigo
        	}
    	}
}

proc cargar_clases_bd { } {
    
	debug "Cargando clases con opcion [::winix::obtiene_valor programas bd ]"	

	avance "Cargando sistema principal... Clases DIM-MT."
	# CARGANDO CLASES DE LA TABLA DIM_MT
	set ::winix_generales(base_datos)  dimdb
	set programas [mysqlsel [::winix::obtiene_valor base_LAN ] "
        	select Codigo,Programa,UsuarioModificacion,Descripcion from [::winix::obtiene_valor dimdb Winix_MT].entorno_trabajo
        	where   TipoPrograma = 'Clases'
    	" -flatlist ]
    
	foreach {codigo programa usuario descripcion} $programas {
		set ::winix_generales(codigo) $codigo
		set ::winix_generales(descripcion) $descripcion
        	debug "Cargando $codigo modificado por $usuario .- $descripcion" 4
        	debug $programa 25
        	if [ catch { eval $programa } resultado ] {
			tronar $resultado clases $usuario
        	}
    	}

	if { "[::winix::obtiene_valor modo_web falso]" == "Cierto"} {
		avance "Cargando sistema principal... Clases WITC."
		# CARGANDO CLASES DE LA TABLA DIM_MT
		set ::winix_generales(base_datos)  dimdb
		set programas [mysqlsel [::winix::obtiene_valor base_LAN ] "
			select Codigo,Programa,UsuarioModificacion,Descripcion from [::winix::obtiene_valor dimdb Winix_MT].entorno_trabajo
			where   TipoPrograma = 'ClasesWITC'
		" -flatlist ]
		
		foreach {codigo programa usuario descripcion} $programas {
			set ::winix_generales(codigo) $codigo
			set ::winix_generales(descripcion) $descripcion
			debug "Cargando $codigo modificado por $usuario .- $descripcion" 4
			debug $programa 25
			if [ catch { eval $programa } resultado ] {
				tronar $resultado clases $usuario
			}
		}
	} else {	
		avance "Cargando sistema principal... Clases TK."
		# CARGANDO CLASES DE LA TABLA DIM_MT
		set ::winix_generales(base_datos)  dimdb
		set programas [mysqlsel [::winix::obtiene_valor base_LAN ] "
			select Codigo,Programa,UsuarioModificacion,Descripcion from [::winix::obtiene_valor dimdb Winix_MT].entorno_trabajo
			where   TipoPrograma = 'ClasesGUI'
		" -flatlist ]
		
		foreach {codigo programa usuario descripcion} $programas {
			set ::winix_generales(codigo) $codigo
			set ::winix_generales(descripcion) $descripcion
			debug "Cargando $codigo modificado por $usuario .- $descripcion" 4
			debug $programa 25
			if [ catch { eval $programa } resultado ] {
				tronar $resultado clases $usuario
			}
		}
	}

}

proc cargar_procesos_bd { } {
	debug "Cargando Procesos con opcion [::winix::obtiene_valor programas bd ]"

	avance "Cargando sistema principal... Procesos."
	set ::winix_generales(base_datos)  sistemasdb
	set programas [mysqlsel [::winix::obtiene_valor base_LAN ] "
		select Codigo,Programa,UsuarioModificacion,Descripcion from [::winix::obtiene_valor sistemasdb [::winix::obtiene_valor nombre_base_cargador winix]_sistema ].programas
			where   TipoPrograma = 'Proceso'
			and (Proyecto = 'BASEDIM' or Proyecto = '[::winix::obtiene_valor proyecto WINIX ]')
		" -flatlist ]

	foreach {codigo programa usuario descripcion} $programas {
		set ::winix_generales(codigo) $codigo
		set ::winix_generales(descripcion) $descripcion
		debug "Cargando $codigo modificado por $usuario .- $descripcion" 4
		debug $programa 25
		if [ catch { eval $programa } resultado ] {
			tronar resultado usuario
		}
    	}
    
	avance "Cargando sistema principal... Procesos DIM-MT."
	# CARGANDO PROCESOS DE LA TABLA DIM_MT
	set ::winix_generales(base_datos)  dimdb
	set programas [mysqlsel [::winix::obtiene_valor base_LAN ] "
        	select Codigo,Programa,UsuarioModificacion,Descripcion from [::winix::obtiene_valor dimdb Winix_MT].entorno_trabajo
        	where   TipoPrograma = 'Proceso'
    	" -flatlist ]

	foreach {codigo programa usuario descripcion} $programas {
		set ::winix_generales(codigo) $codigo
		set ::winix_generales(descripcion) $descripcion
	        debug "Cargando $codigo modificado por $usuario .- $descripcion" 4
	        debug $programa 25
	        if [ catch { eval $programa } resultado ] {
			tronar $resultado procesos $usuario
        	}
    	}

	debug "Cargando Configuraciones con opcion [::winix::obtiene_valor programas bd ]"
    
	avance "Cargando sistema principal... Configuracion DIM-MT."
	# CARGANDO CONFIGURACION DE LA TABLA DIM_MT
	set ::winix_generales(base_datos)  dimdb
	set programas [mysqlsel [::winix::obtiene_valor base_LAN ] "
    		select Codigo,Programa,UsuarioModificacion,Descripcion from [::winix::obtiene_valor dimdb Winix_MT].entorno_trabajo
    	where   TipoPrograma = 'Configuracion'
    	" -flatlist ]
    
   	foreach {codigo programa usuario descripcion} $programas {
		set ::winix_generales(codigo) $codigo
		set ::winix_generales(descripcion) $descripcion
		debug "Cargando $codigo modificado por $usuario .- $descripcion" 4
		debug $programa 25
		if [ catch { eval $programa } resultado ] {
			tronar $resultado clases $usuario $codigo
		}
   	}

}

proc cargar_configuraciones_bd { } {
	debug "Cargando Configuraciones GUI con opcion [::winix::obtiene_valor programas bd ]"
	
	# CARGANDO CONFIGURACION DE LA TABLA DIM_MT
	set ::winix_generales(base_datos)  dimdb
	set programas [mysqlsel [::winix::obtiene_valor base_LAN ] "
    		select Codigo,Programa,UsuarioModificacion,Descripcion from [::winix::obtiene_valor dimdb Winix_MT].entorno_trabajo
    	where   TipoPrograma = 'ConfiguracionGUI'
    	" -flatlist ]
    
   	foreach {codigo programa usuario descripcion} $programas {
		set ::winix_generales(codigo) $codigo
		set ::winix_generales(descripcion) $descripcion
        	debug "Cargando $codigo modificado por $usuario .- $descripcion" 4
		debug $programa 25
		if [ catch { eval $programa } resultado ] {
			tronar $resultado clases $usuario $codigo
		}
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
		::winix::consola_mensaje "[::thread::id] -> [::winix::obtiene_valor base_LAN] <=" 20
		catch { mysqlclose [::winix::obtiene_valor base_LAN] }
		if {"[::winix::obtiene_valor dedicado Cierto]" eq "Cierto"} {
		} else {
			::winix::consola_mensaje "[::thread::id] -> [::winix::obtiene_valor base_WAN] <======= WAN" 20
			catch { mysqlclose [::winix::obtiene_valor base_WAN] }
		}
	}
	if { "$modalidad" == "servidor" } {
		::winix::asigna_valor usuario 	[::winix::obtiene_valor web_usuario Error] servidor "Inicio de usuario para servidor web"
		::winix::asigna_valor clave 	[::winix::obtiene_valor web_clave Error]   servidor "Inicio de usuario para servidor web"
		set modalidad completa
	}

	::winix::consola_mensaje "Pidiendo la configuracion $modalidad $usuario $clave" 1

	switch $modalidad {
		completa {

			debug "Cargando configuracion desde el servidor local -host [::winix::obtiene_valor servidor_LAN localhost] -user [::winix::obtiene_valor usuario Error] -password **************"

			avance "Conectandose a base de datos..."
			if {"[::winix::obtiene_valor ssl Falso]" == "Cierto"} {
				if [ catch { ::winix::asigna_valor base_LAN [
					mysqlconnect -host [::winix::obtiene_valor servidor_LAN localhost] \
							-user [::winix::obtiene_valor usuario Error] \
							-password [::winix::obtiene_valor clave] \
							-ssl True \
							-sslkey  [ ::winix::obtiene_valor sslkey ] \
							-sslcert [ ::winix::obtiene_valor sslcert ] \
							-sslca   [ ::winix::obtiene_valor sslca ] \
							-compress true \
							] \
							Cargador \
							Conexion } resultado ] {
					mensaje_log "ERROR: $resultado" Conexion LOCAL
					return "Error 01: Revise configuracion del sistema. ( [::winix::obtiene_valor servidor_LAN localhost] )"
				}
			} else {
				if [ catch { ::winix::asigna_valor base_LAN [
					mysqlconnect -host [::winix::obtiene_valor servidor_LAN localhost] \
							-user [::winix::obtiene_valor usuario Error] \
							-password [::winix::obtiene_valor clave] ] \
							Cargador \
							Conexion } resultado ] {
					mensaje_log "ERROR: $resultado" Conexion LOCAL
					return "Error 01: Revise configuracion del sistema. ( [::winix::obtiene_valor servidor_LAN localhost] )"
				}
			}

			::winix::consola_mensaje "[::thread::id] -> [::winix::obtiene_valor base_LAN]" 20

			::winix::asigna_valor base_WAN [::winix::obtiene_valor base_LAN ] Cargador Prevision

			if [ catch { mysqluse [::winix::obtiene_valor base_LAN ] [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ] } resultado ] {
				mensaje_log "LOCAL: $resultado" [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ]
				return "Error 02: Revise configuracion del sistema. ( [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ] )"
			}    

			avance "Leyendo Configuración del sistema..."
			if [ catch { set conf [mysqlsel [::winix::obtiene_valor base_LAN ] "select variable,valor
				from configuracion_local where Usuario = ''
				" -flatlist] } resultado ] {
				mensaje_log "LOCAL: $resultado" [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ] Configuracion
				return "Error 03: Revise configuracion del sistema."
			}
			if { "$conf" == "" } {
				mensaje_log " No se encontró ningun registro en la tabla Configuración !!!" [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ] Configuracion
				problemas "Error 04: No hay datos en la tabla de configuraciones !" "El programa no puede iniciar"
			}

			foreach {var val} $conf {
				::winix::asigna_valor $var $val Mysql General
			}

			avance "Leyendo Configuración del usuario..."
			if [ catch { set conf [mysqlsel [::winix::obtiene_valor base_LAN ] "select variable,valor
						from configuracion_local where Usuario = '[::winix::obtiene_valor usuario Error]'
						" -flatlist] } resultado ] {
				mensaje_log "LOCAL: $resultado" [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ] Configuracion
				return "Error 05: No pude cargar configuracion local de [::winix::obtiene_valor usuario Error]"
			}
			avance "Procesando Configuración del usuario..."
			if { "$conf" != "" } {
				foreach {var val} $conf {
			avance "Procesando Configuración del usuario...$var <- $val"
					::winix::asigna_valor $var $val Mysql Usuario
				}
			}

			avance "Leyendo Configuración de Sucursal..."
			if [ catch { set conf [mysqlsel [::winix::obtiene_valor base_LAN ] "
				SELECT 
					suc.CodigoEmpresa,
					ser.Host,
					ser.BaseDatos,
					suc.Es_Corporativo,
					suc.CodigoAlmacen,
					suc.Descripcion, 
					emp.Descripcion
				FROM `catalogosucursales` as suc
				left join catalogosucursales as cor
					on suc.CodigoEmpresa = cor.CodigoEmpresa 
						and cor.Es_Corporativo = '1'
				left join servidores as ser
					on cor.Codigo = ser.Codigo
				left join catalogoempresas as emp
					on emp.Codigo = suc.CodigoEmpresa
				where suc.Codigo = '[::winix::obtiene_valor codigo_sucursal 001]'
								" -flatlist] } resultado ] {
				mensaje_log "LOCAL: $resultado" [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ] Configuracion
				return "Error 07: Faltan tablas base de configuracion"
			}
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

			if { "[::winix::obtiene_valor plataforma gui ]" == "witc" } {
				avance "Leyendo Configuración de plataforma..."
				if [ catch { set conf [mysqlsel [::winix::obtiene_valor base_LAN ] "select variable,valor
						from configuracion_local where Usuario = 'plataforma_web'
						" -flatlist] } resultado ] {
					mensaje_log "LOCAL: $resultado" [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ] Configuracion
					return "Error 05: No pude cargar configuracion local de plataforma_web"
				}
				avance "Procesando Configuración de plataforma..."
				if { "$conf" != "" } {
					foreach {var val} $conf {
						avance "Procesando Configuración del usuario...$var <- $val"
						::winix::asigna_valor $var $val Mysql Usuario
					}
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
					return "Error 01: Revise configuracion del sistema. ( [::winix::obtiene_valor servidor_LAN localhost] )"
				}
			} else {
				if [ catch { set tmp_con [ mysqlconnect -host [::winix::obtiene_valor servidor_LAN localhost] \
							-user [::winix::obtiene_valor usuario Error] \
							-password [::winix::obtiene_valor clave] \
							] 
					} resultado ] {
					mensaje_log "ERROR: $resultado" Conexion LOCAL
					return "Error 01: Revise configuracion del sistema. ( [::winix::obtiene_valor servidor_LAN localhost] )"
				}
			}
			
			if [ catch { mysqluse $tmp_con [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ] } resultado ] {
				mensaje_log "LOCAL: $resultado" [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ]
				return "Error 02: Revise configuracion del sistema. ( [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ] )"
			}
			avance "Leyendo configuracion del usuario..."
			if [ catch { set conf [mysqlsel $tmp_con "
					select valor
					from configuracion_local 
					where Usuario = '[::winix::obtiene_valor usuario Error]'
					and Variable = 'web_administrador'
						" -flatlist] } resultado ] {
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

	if [ catch { set menu_sistema [mysqlsel [::winix::obtiene_valor base_LAN ] "
		select GP.Menu,P.Descripcion,lcase(P.Codigo),atajo,Nivel,Etapa 
			from empleados as E 
				left join catalogopuestos as CP on E.CodigoPuesto = CP.Codigo 
				left join grupos as G on CP.CodigoGrupo$tipo_plataforma = G.Codigo 
				left join gruposprogramas as GP on GP.CodigoGrupo = CP.CodigoGrupo$tipo_plataforma
				left join [::winix::obtiene_valor sistemasdb [::winix::obtiene_valor nombre_base_cargador winix]_sistema ].programas as P on GP.Programa = P.Codigo
				where E.usuario = '$usuario'
				and (Proyecto = 'BASEDIM' or Proyecto = '[::winix::obtiene_valor proyecto WINIX ]')
				and Etapa != 'Disponible'
				order by GP.Orden
							" -flatlist] } resultado ] {
		mensaje_log "LOCAL: $resultado" [::winix::obtiene_valor db [::winix::obtiene_valor nombre_base_cargador winix]_datos ] Configuracion
		problemas "Error 08: No se pudo recuperar menu para usuario $usuario." $resultado
    }

    if [ catch { set menu_dimmt [mysqlsel [::winix::obtiene_valor base_LAN ] "
        select GP.Menu,P.Descripcion,lcase(P.Codigo),atajo,Nivel,Etapa
        from empleados as E
        left join catalogopuestos as CP on E.CodigoPuesto = CP.Codigo
        left join grupos as G on CP.CodigoGrupo$tipo_plataforma = G.Codigo
        left join gruposprogramas as GP on GP.CodigoGrupo = CP.CodigoGrupo$tipo_plataforma
        left join [::winix::obtiene_valor dimdb Winix_MT ].entorno_trabajo as P on GP.Programa = P.Codigo
        where E.usuario = '$usuario'
            and Etapa != 'Disponible'
            order by GP.Orden
        " -flatlist] } resultado ] {
        mensaje_log "LOCAL: $resultado" [::winix::obtiene_valor dimdb Winix_MT ] Menu_Winix_MT
        problemas "Error 09: No se pudo recuperar menu para usuario $usuario" $resultado
    }

    ::winix::consola_mensaje "$menu_sistema $menu_dimmt"
    debug "Menu del usuario $usuario  ---> $menu_sistema $menu_dimmt"

    ::winix::asigna_valor menu "$menu_sistema $menu_dimmt" "Tablas del sistema" "empleados,catalogopuestos,grupos,gruposprogramas,entorno_trabajo"
}

package provide bitacora 1.0

namespace eval bitacora {

	namespace export mensaje

	proc mensaje { mensaje } {                
        
		debug "De la bitacora $mensaje" 1
	}
}
