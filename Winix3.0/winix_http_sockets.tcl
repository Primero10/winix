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
	
	proc ::winix::inicializar { } {
		if [catch {
			set res [consulta_web ::winix::objeto_consulta \
				-IP 		[::winix::obtiene_valor servidor_LAN 	] \
				-usuario 	[::winix::obtiene_valor web_usuario 	] \
				-clave 		[::winix::obtiene_valor web_clave 	] \
				-ssl 		[::winix::obtiene_valor ssl Falso 	] \
				-sslca 		[::winix::obtiene_valor sslca 		] \
				-sslcert 	[::winix::obtiene_valor sslcert 	] \
				-sslkey 	[::winix::obtiene_valor sslkey 		] \
				-persistente	Falso \
				-Servidor	IP \
			]
		} resultado ] {
			::winix::consola_mensaje "Error al crear objeto global de consultas $resultado" -4
		}

		set resultado [obtiene_configuracion servidor]

		puts "[::thread::id] ->Hilo socket creado"
	}
	
	proc ::winix::finalizar { } {
		catch { destroy ::winix::objeto_consulta }
		catch { destroy ::winix::objeto_consulta_web }
		puts "[::thread::id] ->Hilo socket destruido"
	}

	proc ::winix::accept {sock ip port} {
		::thread::attach $sock
		
		set line ""
		set msg "Realmente?"

		set ::winix::encabezados_pedidos ""
		::winix::consola_mensaje "Peticion de $ip: puerto $port, socket $sock" 5
		if [ catch { gets $sock line } ] {
			close $sock
			return 
		}
		if {"$line" == ""} {
			close $sock
			return
		}
		set method  [ lindex $line 0]
		set url     [ lindex $line 1]
		set version [ lindex $line 2]

		set uri [ uri::split $url ]
		array set ::winix::req $uri
		set ruta $::winix::req(path)

		set metodo [ lindex [ split $ruta / ] 0 ]

		if { "$metodo" == "wss"} {
			::winix::consola_wss_entrada "Conexion wss: $sock\n$line" limpia
			::winix::consola_mensaje "El metodo fue wss $method - $version - $url" 3
		} else {
			::winix::consola_entrada "Conexion http: $sock\n$line" limpia
			::winix::consola_mensaje "Procesando peticion normal $line" 3
		}

		::winix::handler $metodo $sock $ip $port $line
	}

	proc ::winix::handler {metodo sock ip port line} {
		::winix::consola_mensaje "$sock - $ip - $port - $line" 3

		if {[catch {
			set auth ""
			set encabezados ""
			for {set c 0} {[gets $sock temp]>=0 && $temp ne "\r" && $temp ne ""} {incr c} {
				lappend ::winix::encabezados_pedidos $temp
				::winix::consola_entrada $temp
				set codigo [lindex [ split $temp : ] 0 ]
				regexp "$codigo: (\[^\r\n\]+)" $temp -- dato
				lappend encabezados "$codigo" $dato
				if {$c == 30} { puts "Too many lines from $ip"; return }
			}
			if {[eof $sock] && "$line" == ""} { puts "Connection closed from $ip por ( $line )"; return }
			foreach {method url version} $line { break }
			::winix::consola_mensaje "Parseando encabezado" 4

			::winix::parse_encabezado
			
			::winix::consola_mensaje "Parseando url" 4
			array set ::winix::req [uri::split $url]

			if {"$method" != "POST" && "$method" != "GET"} {
				error "Unsupported method '$method' from $ip"
			}
		} msg]} {
			puts "$msg"
		}

		set configuracion_lista [ ::winix::carga_configuracion_web $::winix::html_elementos(Host) ]

		puts $configuracion_lista
		if { "[lindex $configuracion_lista 0]" == "deploy" } {
			::winix::responde_tml $sock pagos.tml
			catch { destroy ::winix::objeto_consulta_web }

			close $sock
			return
		}

		if { "$configuracion_lista" == "" } {
			::winix::responde_html $sock 200 "<html><body><h1>Dominio no esta definido para tener pagina web</h2></body></html>"
			catch { destroy ::winix::objeto_consulta_web }

			close $sock
			return
		}

		::winix::consola_mensaje "$sock - $ip - $port - $::winix::html_elementos(Host) - $line"
		
		if {"$metodo" == "wss"} {
			foreach { proyecto cliente var val } $configuracion_lista {
				::tsv::set $sock $var $val
			}
			::tsv::set $sock encabezados $encabezados
			::winix::pool_hilos $sock $ip $port $line

			catch { destroy ::winix::objeto_consulta_web }

			return
		}

		switch -glob $::winix::req(path) {
			"" {
				::winix::responde_tml $sock homepage.tml
			}
			"estetica/*" {
				regexp "estetica/(\[^\r\n\]+)" $::winix::req(path) -- hoja_estilo
				::winix::responde_estetica $sock $hoja_estilo $::winix::html_elementos(If-Modified-Since)
			}
			"scripts/*" {
				regexp "scripts/(\[^\r\n\]+)" $::winix::req(path) -- script
				::winix::responde_script $sock "scripts" $script $::winix::html_elementos(If-Modified-Since)
			}
			"BASEDIM/*" {
				regexp "BASEDIM/(\[^\r\n\]+)" $::winix::req(path) -- script
				::winix::responde_script $sock "BASEDIM" $script $::winix::html_elementos(If-Modified-Since)
			}
			"*.html" {
				if [info exists ::winix::paginas_integradas($::winix::req(path))] {
					::winix::responde_html $sock 200 $::winix::paginas_integradas($::winix::req(path)) $::winix::html_elementos(If-Modified-Since)
				} else {
					::winix::responde_archivo $sock $::winix::req(path) $::winix::html_elementos(If-Modified-Since)
				}
			}
			default {
				# Punto de Seguridad Auditoria PSA (Revisar que no puedan caminar por los directorios)
				::winix::consola_mensaje "Respondiendo pagina $::winix::req(path)" 14
				::winix::responde_archivo $sock $::winix::req(path) $::winix::html_elementos(If-Modified-Since)
			}
		}
		debug "Cerrando socket $sock"
		
		catch { destroy ::winix::objeto_consulta_web }

		close $sock
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
			Upgrade-Insecure-Requests	""
			If-Modified-Since		""
		}
	}
	proc ::winix::carga_mimes {} {
		set mime_file [open mime.types r]
		set mime_contenido [read $mime_file]
		foreach linea [ split $mime_contenido "\n"] {
			set tipo [lindex $linea 0]
			set extensiones [ lrange $linea 1 end]
			foreach ext $extensiones {
				set ::winix::mimes($ext) $tipo
			}
		}
		close $mime_file
	}
	proc ::winix::tipo_mime {path} {
		set tipo text/plain
		if [ catch {set tipo $::winix::mimes([file extension $path])} resultado ] {
			::winix::consola_mensaje "El tipo mime [file extension $path] para $path no se localizo, complemente servidor" 12
		}
		return $tipo
	}
	proc ::winix::formato_fecha {seconds} {
		return [clock format $seconds -format {%a, %d %b %Y %T %Z}]
	}
	proc ::winix::parse_encabezado { } {
		::winix::limpia_encabezados
		foreach linea $::winix::encabezados_pedidos {
			if {"[string range $linea 0 2]" == "GET"} {
				set ::winix::html_elementos(GET) [string range $linea 4 end ]
			} else {
				set codigo [lindex [ split $linea : ] 0 ]
				set dato ""
				if [info exists ::winix::html_elementos($codigo)] {
					regexp "$codigo: (\[^\r\n\]+)" $linea -- dato
					set ::winix::html_elementos($codigo) $dato
					::winix::consola_mensaje " $codigo <=== $::winix::html_elementos($codigo)" 21
				} else {
					::winix::consola_mensaje " (((((((((( $codigo )))))))))) ( $dato )" 10
				}
			}
		}
	}
	
	proc ::winix::responde_html {sock code body {head ""} {cokie ""} } {
		set pagina "$head\n$body"
		set paquete "HTTP/1.0 $code ???\nContent-Type: text/html; charset=ISO-8859-1\nConnection: close\n$pagina"
		::winix::consola_salida $paquete limpia
		puts -nonewline $sock $paquete
	}

	proc ::winix::responde_css {sock code body {head ""} {cokie ""} } {
		::winix::consola_salida $body limpia
		puts -nonewline $sock "HTTP/1.0 $code ???\nContent-Type: text/css; charset=ISO-8859-1\nConnection: close\nContent-length: [string length $body]\n$head\n$body"
	}

	proc ::winix::responde_js {sock code body {head ""} {cokie ""} } {
		::winix::consola_salida $body limpia
		puts -nonewline $sock "HTTP/1.0 $code ???\nContent-Type: application/x-javascript; charset=ISO-8859-1\nConnection: close\nContent-length: [string length $body]\n$head\n$body"
	}

	proc ::winix::responde_archivo { sock archivo {since ""} } {
#		fconfigure $sock -blocking 0 			;# Punto de Seguridad Auditoria PSA
		puts "..."
		set ruta_completa [ file join [::winix::obtiene_valor directorio .] [::winix::obtiene_valor_web directorio_web homepage ] $archivo ]
		puts "..."
		if { "$since" != "" } {
			puts "...>>>"
			set requerido [ clock scan $since ]
			set actual $requerido
			puts ".... $requerido )))"

			if [catch {set actual [file mtime $ruta_completa] } resultado ] {
				puts "No pude revisar la hora $resultado"
				puts ".... $requerido <> $actual"
				::winix::consola_mensaje "No se encontro $ruta_completa" 6
				::winix::enviar $sock "HTTP/1.0 404 Not found"
				::winix::enviar $sock ""
				::winix::enviar $sock "<html><head><title><No existe esta liga $archivo></title></head>"
				::winix::enviar $sock "<body><center><h1>"
				::winix::enviar $sock "The URL you requested does not exist on this site $archivo.</h1>"
				::winix::enviar $sock "</center>$ruta_completa</body></html>"
				return
			}
			puts "_______"
			if { $requerido >= $actual} {
				puts "Ya lo tenian en cache!!!"
				::winix::consola_mensaje "Lo tenian en cache $ruta_completa" 6
				::winix::enviar $sock "HTTP/1.0 304 Not Modified"
				::winix::enviar $sock ""
				return
			}
		}

		puts "<<<"

		if {[catch {set fileChannel [open $ruta_completa RDONLY] } resultado ]} {
			::winix::consola_mensaje "No se encontro $ruta_completa" 6
			::winix::enviar $sock "HTTP/1.0 404 Not found"
			::winix::enviar $sock ""
			::winix::enviar $sock "<html><head><title><No existe esta liga $archivo></title></head>"
			::winix::enviar $sock "<body><center><h1>"
			::winix::enviar $sock "The URL you requested does not exist on this site $archivo.</h1>"
			::winix::enviar $sock "</center>$ruta_completa</body></html>"
		} else {
			::winix::consola_mensaje "Se entrego $ruta_completa :: Content-Type: [::winix::tipo_mime $ruta_completa]" 6
			fconfigure $fileChannel -translation binary
			fconfigure $sock -translation binary -buffering full
			::winix::enviar $sock "HTTP/1.0 200 Data follows"
			::winix::enviar $sock "Date: [::winix::formato_fecha [clock seconds]]"
			::winix::enviar $sock "Last-Modified: [::winix::formato_fecha [file mtime $ruta_completa]]"
			::winix::enviar $sock "Content-Type: [::winix::tipo_mime $ruta_completa]"
			::winix::enviar $sock "Content-Length: [file size $ruta_completa]"
			::winix::enviar $sock ""
			fcopy $fileChannel $sock
		}
	}
	proc ::winix::responde_pagina { sock {pagina ""} since} {
#		fconfigure $sock -blocking 0	;# Punto de Seguridad Auditoria PSA

		::winix::consola_mensaje "Respondiendo pagina $pagina" 7
		::winix::responde_html $sock 200 [::winix::pagina.tml ejecutar $pagina]
	}
	proc ::winix::responde_principal { sock {pagina ""} } {
#		fconfigure $sock -blocking 0	;# Punto de Seguridad Auditoria PSA

		::winix::consola_mensaje "Respondiendo pagina $pagina" 7
		::winix::responde_html $sock 200 [::winix::portal_carga_pagina $pagina ::winix::objeto_consulta_web ]
	}
	proc ::winix::responde_tml { sock script {parametro ""}} {
		::winix::consola_mensaje "Regresando tml $script con parametro $parametro de longitud $::winix::html_elementos(Content-Length)" 7
		
		if {"$::winix::html_elementos(Content-Length)" != ""} {
			set cadenota [ read $sock $::winix::html_elementos(Content-Length) ]
		
			::winix::poner_elementos_formulario $cadenota
		}

		if { [ llength [ info commands ::winix::$script ] ] != 0 } {
			::winix::responde_html $sock 200 [ ::winix::$script ejecutar $parametro]
		} else {
			::winix::responde_html $sock 404 "No existe un archivo $script"
		}
	}
	proc ::winix::responde_estetica { sock codigo since } {
		::winix::consola_mensaje "Procesando $codigo del proyecto [::winix::obtiene_valor_web proyecto Winix]" 2

		set datos [ ::winix::objeto_consulta_web consulta_express "
			SELECT Script
			from <*servidor_web*>
			where Codigo='$codigo' 
				and Tipo_Pagina='Estetica' 
				and Proyecto='[::winix::obtiene_valor_web proyecto Winix]'
		" flatlist ]

		if { "$datos" != ""} {
			::winix::consola_mensaje "Respondido" 2
			::winix::responde_css $sock 200 [ lindex $datos 0 ]
		} else {
			::winix::responde_html $sock 404 "No existe una hoja de estilo con codigo $codigo"
		}
	}

	proc ::winix::responde_script { sock proyecto codigo since } {
		::winix::consola_mensaje "Procesando $codigo del $proyecto" 1

		if { "$proyecto" == "scripts"} {
			set datos [ ::winix::objeto_consulta_web consulta_express "
				SELECT Script
				from <*servidor_web*>
				where Codigo='$codigo' 
					and Tipo_Pagina='Script' 
					and Proyecto='[::winix::obtiene_valor proyecto Winix]'
			" flatlist ]
		} else {
			set datos [ ::winix::objeto_consulta_web consulta_express "
				SELECT Script
				from <*servidor_web*>
				where Codigo='$codigo' 
					and Tipo_Pagina='Script' 
					and Proyecto='$proyecto'
			" flatlist ]
		}
		
		if { "$datos" != ""} {
			::winix::responde_js $sock 200 [ lindex $datos 0 ]
		} else {
			::winix::consola_mensaje "Que crees!!! no hay codigo $codigo en el proyecto $proyecto !!!" 7
			::winix::responde_html $sock 404 "No existe una script con codigo $codigo"
		}
	}

	proc ::winix::enviar { sock cadena } {
		::winix::consola_salida "$cadena"
		puts $sock $cadena
	}

	proc carga_configuracion_web { host } {
	
		set datos [ ::winix::objeto_consulta consulta_express "
			select witc_nivel from powerdns.records where name = '$host' and type = 'A' 
		" flatlist ]

		if { "$datos" != "0" } {
			puts "$host esta en proceso de deploy"
			return "deploy $datos"
		}

		set datos [ ::winix::objeto_consulta consulta_express "
			SELECT proyecto,cliente,variable,valor
			from <*witc_dominios*>
			where valor='$host'
			and variable='web_dominio_virtual' 
		" flatlist ]

		if { "$datos" == "" } {
			puts "$host no se encontro..."
			return ""
		} else {
			puts "$host tiene los datos $datos"
		}

		set proyecto [lindex $datos 0]
		set cliente [lindex $datos 1]

		::winix::consola_mensaje "host $host proyecto $proyecto cliente $cliente datos $datos" 2

		set datos [ ::winix::objeto_consulta consulta_express "
			SELECT proyecto,cliente,variable,valor
			from <*witc_dominios*>
			where proyecto='$proyecto'
			and cliente='$cliente' 
		" flatlist ]

		::winix::elimina_variables_web
		
		foreach { proyecto cliente var val } $datos {
			::winix::asigna_valor_web $var $val virtualidad witc_dominios
		}

		catch { delete object ::winix::objeto_consulta_web }

		set resultado ""
		if [ catch {
			consulta_web ::winix::objeto_consulta_web \
				-IP 		[::winix::obtiene_valor_web servidor_LAN 	] \
				-usuario 	[::winix::obtiene_valor_web web_usuario 	] \
				-clave 		[::winix::obtiene_valor_web web_clave	 	] \
				-ssl 		[::winix::obtiene_valor_web ssl Falso 		] \
				-sslca 		[::winix::obtiene_valor_web sslca 		] \
				-sslcert 	[::winix::obtiene_valor_web sslcert 		] \
				-sslkey 	[::winix::obtiene_valor_web sslkey 		] \
				-bd 		[::winix::obtiene_valor_web db 			] \
				-bd_sistema 	[::winix::obtiene_valor_web sistemasdb 		] \
				-bd_winix	[::winix::obtiene_valor_web dimdb 		] \
				-Servidor	IP \
				-persistente	Falso
		} resultado ] {
			::winix::consola_mensaje "Error creando objeto $resultado" -4
		}

		return $datos

	}
}

proc avance { args } {
}

tml ::winix::pagina.tml {
	[::winix::portal_carga_pagina $siguiente_pagina ::winix::objeto_consulta_web ]
}

tml ::winix::homepage.tml {
	<html>
		<head>
			<meta charset="iso8859-1" />
			<title>[::winix::obtiene_valor_web sistema]</title>
			<link type="text/css" rel="stylesheet" media="screen" href="https://cdn.conversejs.org/css/converse.min.css" />

			<link rel="stylesheet" id=stylesheet href="/jquery-ui/themes/[::winix::obtiene_valor_web jquery_tema start]/jquery-ui.css">

    			<script src="/jquery-ui-1.11.2/jquery-1.11.2.js"></script>
			<script src="/jquery-ui-1.11.2/jquery-ui.js"></script>
			<script src="/jstree/jstree.min.js"></script>

			<script src="/js/handsontable.full.js"></script>
			<script src="/js/jquery.table2csv.min.js"></script>

			<script src="/print.js"></script>

			<script src="src/ace.js" type="text/javascript" charset="utf-8"></script>
			
			<link rel="stylesheet" media="screen" href="/css/handsontable.full.css">
			<link rel="stylesheet" href="/jstree/themes/default/style.min.css" />

			<!-- SmartMenus core CSS (required) -->
			<link href="/smartmenus-1.0.0/css/sm-core-css.css" rel="stylesheet" type="text/css" />

			<!-- "sm-blue" menu theme (optional, you can use your own CSS, too) -->
			<link href="/smartmenus-1.0.0/css/sm-blue/sm-blue.css" rel="stylesheet" type="text/css" />

			<link rel="stylesheet" href="estetica/[::winix::obtiene_valor_web web_estetica_menu 000020]" type="text/css" media="screen">
			<link rel="stylesheet" href="estetica/[::winix::obtiene_valor_web web_estetica_estado 000018]" type="text/css" media="screen">
			<link rel="stylesheet" href="estetica/[::winix::obtiene_valor_web web_estetica_programa 000019]" type="text/css" media="screen">
			<link rel="stylesheet" href="estetica/[::winix::obtiene_valor_web web_css 000005]" type="text/css" media="screen">

			<script>
				var wss_url = "[::winix::obtiene_valor_web web_dominio_wss ][::winix::obtiene_valor_web web_puerto_url ]/wss";
				var main_url = "[::winix::obtiene_valor_web web_dominio ][::winix::obtiene_valor_web web_puerto ]/";
			</script>

			<script src="/BASEDIM/[::winix::obtiene_valor_web web_wcp 000001 ]" type="text/javascript"></script>

			<!-- SmartMenus jQuery plugin -->
			<script type="text/javascript" src="/smartmenus-1.0.0/jquery.smartmenus.js"></script>

			<script src="https://cdn.conversejs.org/2.0.1/dist/converse.nojquery.min.js"></script>

		</head>
		<body>
			<div id="instancias"></div>
			<div id="impresiones"></div>
			<div id="mensajeria"></div>
			<div id=principal>
				[ ::winix::portal_carga_principal [::winix::obtiene_valor_web web_homepage ] ]
			</div>
		</body>
    </html>
}

tml ::winix::pagos.tml {
	<html>
		<head>
			<meta charset="iso8859-1" />
			<title>Empresa en proceso de pago</title>

		</head>
		<body>
			<img src=https://www.takmab.mx/imagenes/pagos.jpg align=left>
			<h1>Este dominio esta registrado y apartado</h1>
			<fieldset>
			<legend>El proceso para ser concluido, requiere los siguientes pasos:</legend>
			<ol>
			<li>Realizar el pago, mediante paypal o transferencia bancaria, según su elección al registrar.
			<li>Acreditar el pago, esta labor la realizará Takmab, una vez tengamos en nuestro poder el 
			correo de paypal de su pago ó el correo que nos envie con los datos de la transferencia bancaria.
			<li>Activación del sitio. Esta página será sustituido por su página WEB inicial.
			<li>Deberá ingresar a su sitio con el usuario y clave que eligio durante el registro
			<li>Una vez ingresado, deberá capturar los datos de la empresa, sucursal y almacen. Para
			mayor información consulte las guias que se encuentran en su menú de Ayudas
			</ol>
			</fieldset>
		</body>

	</html>
}
