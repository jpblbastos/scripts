#!/bin/sh
# /**
# *
# * Este arquivo é parte do projeto spoolga - sistema de impressao G. A. Silva
# *
# * Este programa é um software livre: você pode redistribuir e/ou modificá-lo
# * sob os termos da Licença Pública Geral GNU (GPL)como é publicada pela Fundação
# * para o Software Livre, na versão 3 da licença, ou qualquer versão posterior
# * e/ou 
# * sob os termos da Licença Pública Geral Menor GNU (LGPL) como é publicada pela Fundação
# * para o Software Livre, na versão 3 da licença, ou qualquer versão posterior.
# *  
# * Você deve ter recebido uma cópia da Licença Publica GNU e da 
# * Licença Pública Geral Menor GNU (LGPL) junto com este programa.
# * Caso contrário consulte <http://www.fsfla.org/svnwiki/trad/GPLv3> ou
# * <http://www.fsfla.org/svnwiki/trad/LGPLv3>. 
# *
# * @package        spoolga
# * @name           account-processes.sh 
# * @version        2.0
# * @license        http://www.gnu.org/licenses/gpl.html GNU/GPL v.3
# * @copyright      2011 &copy Twoclick Criações
# * @author         Joao Paulo Bastos L. <jpbl.bastos at gmail dot com>
# * @date           20-Fevereiro-2013
# * @description    conta quantos processos foram execultados no dia (impressoes realizadas ou email enviados/flahas)
# *                 ,salva em arquivo de log ou mostra na tela conforme parametro
# * @dependencies   arquivos de configuracao da aplicacao "var_globais" e "conf-printers.xml"
# * @parm           --impressions        - para contagens de impressoes realizadas
# *                 --email              - para contagem de emails enviados
# *                 --display            - so para mostrar na tela
# *
# **/  x'

#  // propriedades do script

# /**
# * sysconfig_spoolga
# * arquivo de variaveis globais
# * @var int
# */
: ${sysconfig_spoolga:=/opt/spoolga/conf/var_globais}
test -e $sysconfig_spoolga || exit 4
test -x $sysconfig_spoolga || exit 5

# /**
# * nomePrinter
# * nomes das printers
# * @var array
# */
nomePrinter=

# /**
# * onlyDisplay
# * flag que determina se e apenas para mostrar os resultados na tela
# * @var int     i - sim / 0 - nao
# */
onlyDisplay=0

# // fim das propriedades do script

# // funcoes auxiliares

# /**
# * usage
# * Método que metodo de uso do script
# * @version 2.0
# * @package spoolga
# * @author  joao paulo bastos <jpbl.bastos at gmail dot com>
# */
function usage() {
   printf " Uso:\n"
   printf "   $0 [--impressions|--email] {--display}\n\n"
   printf "Opcoes do script:\n"
   printf "   --impressions                        Conta somente os processos de impressoes.\n"
   printf "   --email                              Conta somente os processes de envio de e-mail's.\n"
   printf "   --display                            Apenas mostra na tela.\n"
}

# /**
# * loadConfPrinters
# * Método que carrega arquivo de configurações das printers para array
# * @version 1.0
# * @package spoolga
# * @author  joao paulo bastos <jpbl.bastos at gmail dot com>
# */
function loadConfPrinters(){
   # faz o loop para ler o arquivo de configurações printers e montar array
   for tag in nomePrinter 
   do
      OUT=`grep  $tag $CONFPRINTERS | tr -d '\t' | sed 's/^<.*>\([^<].*\)<.*>$/\1/' `
      # fazendo o eval_trick
      eval ${tag}=`echo -ne \""${OUT}"\"`
   done
   # carregando para os array
   nomePrinter=( `echo ${nomePrinter}` )
} 

# // fim das funcoes

# // corpo do script

# carrega arquivo variaveis globais
. $sysconfig_spoolga

# verifica se ha paramentros suficientes
if [ $# -lt 1 ] || [ $# -gt  3 ]; then
   usage
   exit 1
fi

# faz loop dos parametros para saber se e para gravar ou mostrar na tela
for i in $* ; do
   if [ "$i" = "--display" ] ; then
      onlyDisplay=1
   fi
done

# escreve cabecalho
if [ "$onlyDisplay" -eq 1 ] ; then # somente mostrar
   echo -e "_____________________________________________________________________________\n"
   echo -e "           Estatistica de processos do dia `date +%d.%b.%Y` as `date +%H.%M` "
   echo -e "          ________________________________________________________ \n"
else # para gravar no log
   echo -e "_____________________________________________________________________________\n" >> $LOGSERVICESACCOUNT
   echo -e "           Estatistica de processos do dia `date +%d.%b.%Y` as `date +%H.%M` "   >> $LOGSERVICESACCOUNT
   echo -e "          ________________________________________________________ \n"           >> $LOGSERVICESACCOUNT
fi
  
# faz loop para realizar a contagem
for i in $* ; do
   if [ "$i" = "--impressions" ] ; then # contagem das impressoes 
      # carregas impressoras
      loadConfPrinters
      if [ "$onlyDisplay" -eq 1 ] ; then # somente mostrar
         echo -e "\t\t Impressoes "
      else
         echo -e "\t\t Impressoes " >> $LOGSERVICESACCOUNT
      fi
      # faz o loop no array nomePrinter
      for (( x = 0 ; x < ${#nomePrinter[@]} ; x++ )) 
      do
         qtd=$((0))
         # pega numero de copias de cada printer 
         qtd=`cat $LOGAPP|grep imp|grep ${nomePrinter[$x]}|wc -l` 
         if [ "$onlyDisplay" -eq 1 ] ; then # somente mostrar
            echo -e "\t\t\t└ ${nomePrinter[$x]}  $qtd " 
         else
            echo -e "\t\t\t└ ${nomePrinter[$x]}  $qtd " >> $LOGSERVICESACCOUNT
         fi
      done
      # faz a contagem dos pdf
      qtd=$((0))
      # pega numero de pdf's convertidos com sucesso
      qtd=`cat $LOGAPP|grep relatorio|grep sucesso|wc -l` 
      if [ "$onlyDisplay" -eq 1 ] ; then # somente mostrar
         echo -e "\t\t\t└ Pdf's     $qtd " 
      else
         echo -e "\t\t\t└ Pdf's     $qtd " >> $LOGSERVICESACCOUNT
      fi
   # quando e-mail
   elif [ "$i" = "--email" ] ; then
      qtd=$((0))
      # pega numero de emails enviados com sucesso
      qtd=`cat $LOGAPP|grep E-mail|grep sucesso|wc -l` 
      if [ "$onlyDisplay" -eq 1 ] ; then # somente mostrar
         echo -e "\t\t E-mail's"
         echo -e "\t\t\t└ Sucesso   $qtd "
      else
         echo -e "\t\t E-mail's" >> $LOGSERVICESACCOUNT
         echo -e "\t\t\t└ Sucesso   $qtd " >> $LOGSERVICESACCOUNT
      fi
      qtd=$((0))
      # pega numero de emails  que deram erros
      qtd=`cat $LOGAPP|grep erro|grep e-mail|wc -l` 
      if [ "$onlyDisplay" -eq 1 ] ; then # somente mostrar
         echo -e "\t\t\t└ Falha     $qtd "
      else
         echo -e "\t\t\t└ Falha     $qtd " >> $LOGSERVICESACCOUNT
      fi
   fi
done

# escreve rodape
if [ "$onlyDisplay" -eq 1 ] ; then # somente mostrar
   echo -e "_____________________________________________________________________________\n"
else # para gravar no log
   echo -e "_____________________________________________________________________________\n" >> $LOGSERVICESACCOUNT
fi

# // fim corpo do script
