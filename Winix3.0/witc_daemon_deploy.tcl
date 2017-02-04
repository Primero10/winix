#!/usr/local/bin/tclsh8.6

# Configuracion de WITCDeployDaemon
set daemon_id 21

package require mysqltcl

puts "Proporciona clave de Mysql:"
gets stdin clave

puts "Conectandose a mysql..."

set servidor [ mysqlconnect \
	-host mysql.takmab.mx \
	-user rcuevas \
	-password $clave\
	-ssl True \
	-sslca  /etc/mysql-ssl/ca-cert.pem \
	-sslcert /etc/mysql-ssl/client-cert.pem \
	-sslkey   /etc/mysql-ssl/client-key.pem \
	-compress true ]

puts "Conectado."

proc deploys { } {
	return [ mysqlsel $::servidor "select name from powerdns.records where witc_nivel = $::daemon_id " -flatlist ]
}

proc datos_fiscales { dominio } {
	set datos_dominios [ mysqlsel $::servidor "
		select  Proyecto,
			Cliente
		from pegaso_sistema.witc_dominios 
		where Variable='web_dominio_virtual' 
			and Proyecto='CONTABLES' 
			and Valor = '$dominio'
	" -flatlist ]
	
	set proyecto [ lindex $datos_dominios 0]
	set cliente [ lindex $datos_dominios 1]

	return [ mysqlsel $::servidor "
		select Codigo,
			TipoPersona,
			RazonSocial,
			Nombre,
			ApellidoPaterno,
			ApellidoMaterno,
			Telefono,
			Celular,
			RFC,
			FechaNacimiento,
			EstadoCivil,
			NombreConyuge,
			Ocupacion,
			Email,
			Fax,
			CURP,
			ImagenCliente,
			Actualizado,
			Borrado,
			UsuarioAlta,
			UsuarioModificacion,
			FechaAlta,
			FechaModificacion,
			Utilizado,
			Giro,
			Colonia,
			CodigoPostal,
			Ciudad,
			Municipio,
			Estado,
			Pais 
		from briseli_datos.clientes 
		where codigo='$cliente'" -flatlist ]
}

proc cambiar_witc_nivel { dominio proyecto cliente var val } {
	mysqlexec $::servidor "update powerdns.records set witc_nivel=0 where name = '$dominio' and type='A' "
	mysqlexec $::servidor "
		replace into pegaso_sistema.witc_dominios 
			set Proyecto='$proyecto',
			Cliente = '$cliente',
			Variable='avance_deploy',
			Valor = '',
			and Proyecto='CONTABLES' 
			and Valor = '$dominio'
	" -flatlist ]
}

proc ip_mysql { dominio } {
	return [ lindex [ mysqlsel $::servidor "select content from powerdns.records where type = 'A' and name='mysql.$dominio'" -flatlist ] 0 ]
}

proc deploy { dominio } {
	set mysql [ ip_mysql $dominio ]
	set datos_cliente [ datos_fiscales $dominio ]
	puts "Dominio para deploy $dominio"
	puts "Ip para mysql $mysql"
	puts "Datos fiscales $datos_cliente"
	
	eval [ list exec /usr/local/bin/ezjail-admin create -a witc_jail_base.tar.gz $dominio $mysql ]
	
	cambiar witc_nivel $dominio
}

puts "Deploy ejecutandose."
for { } { 1 } { } {
	puts "."
	foreach dominio [ deploys ] {
		puts "Haciendo deploy de $dominio"
		#deploy $dominio
	}
	after 10000
}


Codigo,TipoPersona,RazonSocial,Nombre,ApellidoPaterno,ApellidoMaterno,Telefono,Celular,RFC,FechaNacimiento,EstadoCivil,NombreConyuge,Ocupacion,Email,Fax,CURP,ImagenCliente,Actualizado,Borrado,UsuarioAlta,UsuarioModificacion,FechaAlta,FechaModificacion,Utilizado,Giro,Colonia,CodigoPostal,Ciudad,Municipio,Estado,Pais


Proyecto,
Cliente,
Usuario,
Variable,
Valor