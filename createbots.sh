#!/bin/bash

CURRENT_DATE=$(date +"%d/%m/%Y") 
DEFAULT_DB="postgres"

# DIM / APP
HOST_SERVER_APP=""
USER_SERVER_APP=""
DB_SERVER_APP=""
PORT_SERVER_APP=""
PASS_SERVER_APP=""

script_path=`dirname "$BASH_SOURCE"`
argsArray=("$@")
argsOpt=("cod-ibge" "cidade" "jid" "type")
bashUsageSample="> ./createbots.sh cod-ibge=261110 cidade=Petrolina-PE jid=pe_petrolina type=S" 

# DB Operations
DELETE_ROBO="DELETE FROM robo WHERE cod_ibge_municipio= "
INSERT_ROBO="INSERT INTO robo (name, last_seen, status, version, active, cod_ibge_municipio, jid, system_category_id) VALUES "
QUERY_CHECK_CONN="SELECT 'DB Connection OK' FROM pg_database LIMIT 1"

if ! [ -x "$(command -v psql)" ]
    then
        echo "ERROR: postgresql-client nao esta instalado. Instale uma versao do postgresql-client e tente novamente"   
        exit -1
elif [ ${#argsArray[@]} -eq 0 ]
    then 
        echo "ERROR: nenhum argumento informado"
        echo "INFO: argumentos validos ==> ${argsOpt[@]}" 
        echo "INFO: exemplo de uso"
        echo $bashUsageSample
        exit -1
fi

for ARGUMENT in "$@"
do

    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)   

    case "$KEY" in
            cod-ibge)
                            CODIBGE=${VALUE}
                            ;;
            cidade)
                            CIDADE=${VALUE}
                            ;;
            jid)
                            JID=${VALUE}
                            ;;

            type)
                            TYPE=${VALUE}
                            ;;
            custom-sql)
                            CUSTOM_SQL_COMMAND=${VALUE}
                            ;;
            *)   
    esac    
done

deleteRegistrosRobo() {
    sqlInstruction="$DELETE_ROBO'"$CODIBGE"';"
    echo "INFO: $sqlInstruction"
    execSQLCommand $sqlInstruction "deleteRegistrosRobo()"
}


# Executa uma instrucao SQL
# $1 Instrução
# $2 Mensagem para debugger (opcional)
execSQLCommand() {
	result=`PGPASSWORD="$PASS_SERVER_APP" psql -U "$USER_SERVER_APP" -d "$DB_SERVER_APP" -h "$HOST_SERVER_APP" -p "$PORT_SERVER_APP" -X -A -t -c "$1"`
	if ! [ $? -eq 0 ] ; then
			echo "Error: problema ao executar instrucao SQL. Instrucao: $1"
            echo "Base: $DB_SERVER_APP"
			exit -1
	fi

    echo "DEBUG: return for [$2] instruction is => $result"

}

main() {
    ARRAY_SISTEMA_S=(SIM-SINASC eSUS CNES SINAN)
    ARRAY_SISTEMA_X=(SIM-SINASC-SINAN eSUS CNES)
    if [ "$1" == "S" ] ; then
        for sis in ${ARRAY_SISTEMA_S[@]} 
        do 
            validaArgsRobo
            registraNovoRobo $sis
        done
    elif [ "$1" == "X" ] ; then
        for sis in ${ARRAY_SISTEMA_X[@]}
        do 
            validaArgsRobo
            registraNovoRobo $sis
        done
    elif [ "$1" == "R" ] ; then
            validaArgsRemocaoRobos
            # deleteRegistrosRobo FIX
    else
        echo "WARN: opcoes disponiveis: S - Simples, X - SIM|SINAN|SINASC juntos, R - Deleta os cadastros para uma dada cidade" 
        exit -1
    fi
}

registraNovoRobo() {
    jidPart=$(sed "s/[\-]\+//g" <<< $1) 
    jidPart="$JID""_""${jidPart,,}"     

    sysPart=$(sed "s/[\-]\+/\ \-\ /g" <<< $1)

    sqlInstruction="$INSERT_ROBO""('$CIDADE - $sysPart', now(), 'DOWN', 11, TRUE , '$CODIBGE', '$jidPart@service.in/service', -23119);"
    echo "INFO: $sqlInstruction" 
    execSQLCommand "$sqlInstruction" "registraNovoRobo()"
}

validaArgsRemocaoRobos() {
  if [ -z "$CODIBGE" ]
        then 
            echo "ERROR: o argumento [cod-ibge] nao foi informado. Informe o codigo do IBGE para que o cadastro de robo possa prosseguir corretamente"
            echo $bashUsageSample
            exit -1
 fi
}

validaArgsRobo() {
    if [ -z "$CODIBGE" ]
        then 
            echo "ERROR: o argumento [cod-ibge] nao foi informado. informe o codigo do IBGE para que o cadastro de robo possa prosseguir corretamente"
            echo $bashUsageSample
            exit -1
    fi

    if [ -z "$CIDADE" ]
        then 
            echo "ERROR: o argumento [cidade] nao foi informado. informe o nome da cidade para que o cadastro de robo possa prosseguir corretamente"
            echo $bashUsageSample
            exit -1
    fi

    if [ -z "$JID" ]
        then 
            echo "ERROR: o argumento [jid] nao foi informado. informe o nome da cidade para que o cadastro de robo possa prosseguir corretamente"
            echo $bashUsageSample
            exit -1
    fi
}

execSQLCommand "$QUERY_CHECK_CONN" "check connection with $DB_SERVER_APP" 
main "$TYPE"

echo "INFO: processo finalizado com sucesso!"
exit 0