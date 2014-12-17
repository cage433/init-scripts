alias nick='ssh nick@nick-linux'
alias dave='ssh dave@dave-linux'
alias stacy='ssh stacy@stacy-linux'
alias louis='ssh louis@louis-linux'
alias thomas='ssh thomas@thomas-linux'
export RORY="rory@rory-ubuntu"
alias rory='ssh $RORY'
alias j6='export JAVA_HOME=/usr/local/jdk6/'
alias j7='export JAVA_HOME=/usr/local/jdk7/'
alias sox='autossh -f -N -D 6666 $CAGE'
alias traf-git='git config user.name Alex.McGuire && git config user.email alex.mcguire@trafigura.com'
alias jvisualvm='$JAVA_HOME/bin/jvisualvm '
alias squirrel='nohup ~/bin/squirrel/squirrel-sql.sh 0<&- &> /home/alex/bin/logs/squirrel.log &'
export JAVA_HOME=/usr/local/jdk7/
alias scla='/usr/local/scala-2.10.2/bin/scala'
alias sng='synergys -c $HOME/synergy.conf'

export http_proxy=http://127.0.0.1:3128
export https_proxy=https://localhost:3128/
export no_proxy=localhost,127.0.0.0/8,nexus,nexus.global.trafigura.com,starlings,ghe,ghe.global.trafigura.com,ttraflocorh197,.global.trafigura.com,nexus,nexus.global.trafigura.com,starlings,ghe,ghe.global.trafigura.com,ttraflocorh197,.global.trafigura.com
alias zinc='$HOME/bin/zinc/bin/zinc -Dzinc.analysis.cache.limit=50' 
alias sbt='$HOME/bin/sbt/bin/sbt'

alias SE01='ssh alex.mcguire@dtraflonrh893 -t "cd /opt/starling_metals/QA-SE01/ ; bash --login" '
alias SE02='ssh alex.mcguire@dtraflocorh183 -t "cd /opt/starling_metals/QA-SE02/ ; bash --login" '
alias SE05='ssh alex.mcguire@dtraflocorh187 -t "sudo su - starling_metals --session-command \"cd QA-SE05; bash --login\"" '
alias SE07='ssh alex.mcguire@dtraflocorh198 -t "sudo su - starling_metals --session-command \"cd QA-SE07; bash --login\"" '
alias SE08='ssh alex.mcguire@dtraflonrh674 -t "cd /opt/starling_metals/QA-SE08/ ; bash --login" '
alias SE09='ssh alex.mcguire@dtraflocorh198 -t "sudo su - starling_metals --session-command \"cd QA-SE09; bash --login\"" '
alias SE10='ssh alex.mcguire@dtraflocorh187 -t "cd /opt/starling_metals/QA-SE10/ ; bash --login" '
alias SE11='ssh alex.mcguire@dtraflocorh184 -t "cd /opt/starling_metals/QA-SE11/ ; bash --login" '
alias SE12='ssh alex.mcguire@dtraflocorh184 -t "cd /opt/starling_metals/QA-SE12/ ; bash --login" '
alias SE15='ssh alex.mcguire@dtraflocorh187 -t "cd /opt/starling_metals/QA-SE15/ ; bash --login" '
alias SE16='ssh alex.mcguire@dtraflonrh674 -t "cd /opt/starling_metals/QA-SE16/ ; bash --login" '
alias SE17='ssh alex.mcguire@dtraflocorh187 -t "cd /opt/starling_metals/QA-SE17/ ; bash --login" '
alias SE19='ssh alex.mcguire@dtraflonrh671 -t "cd /opt/starling_metals/QA-SE19/ ; bash --login" '
alias SE20='ssh alex.mcguire@dtraflonrh674 -t "cd /opt/starling_metals/QA-SE20/ ; bash --login" '
alias SE21='ssh alex.mcguire@dtraflonrh671 -t "cd /opt/starling_metals/QA-SE21/ ; bash --login" '
alias SE23='ssh alex.mcguire@dtraflocorh198 -t "sudo su - starling_metals --session-command \"cd QA-SE23; bash --login\"" '
alias SE24='ssh alex.mcguire@dtraflocorh210 -t "cd /opt/starling_metals/SE24 dtraflocorh210/ ; bash --login" '
alias SE25='ssh alex.mcguire@dtraflonrh674 -t "cd /opt/starling_metals/QA-SE25/ ; bash --login" '
alias SE28='ssh alex.mcguire@dtraflocorh230 -t "cd /opt/starling_metals/QA-SE28/ ; bash --login" '
alias SE29='ssh alex.mcguire@dtraflocorh231 -t "cd /opt/starling_metals/QA-SE29/ ; bash --login" '
alias SE30='ssh alex.mcguire@dtraflonrh671 -t "cd /opt/starling_metals/QA-SE30/ ; bash --login" '
alias SE31='ssh alex.mcguire@dtraflonrh894 -t "cd /opt/starling_metals/QA-SE31/ ; bash --login" '
alias SE32='ssh alex.mcguire@dtraflonrh671 -t "cd /opt/starling_metals/QA-SE32/ ; bash --login" '
alias SE33='ssh alex.mcguire@dtraflocorh183 -t "cd /opt/starling_metals/QA-SE33/ ; bash --login" '
alias SE37='ssh alex.mcguire@dtraflocorh184 -t "cd /opt/starling_metals/QA-SE37/ ; bash --login" '
alias metalsProd='ssh alex.mcguire@ttraflonrh196.global.trafigura.com -t "cd /opt/starling_metals/starling-prod/ ; bash --login" '

alias jvvmMetalsProd="nohup jvisualvm --openjmx ttraflonrh196:52477 > /dev/null 2>&1 &"
alias jvvmSE01="nohup $JAVA_HOME/bin/jvisualvm --openjmx dtraflonrh893:30301 > /dev/null 2>&1 &"
alias jvvmSE01="nohup $JAVA_HOME/bin/jvisualvm --openjmx dtraflonrh893:30301 > /dev/null 2>&1 &"
alias jvvmSE02="nohup $JAVA_HOME/bin/jvisualvm --openjmx dtraflocorh183:30302 > /dev/null 2>&1 &"
alias jvvmSE05="nohup $JAVA_HOME/bin/jvisualvm --openjmx dtraflocorh187:30305 > /dev/null 2>&1 &"
alias jvvmSE08="nohup $JAVA_HOME/bin/jvisualvm --openjmx dtraflonrh674:30308 > /dev/null 2>&1 &"
alias jvvmSE10="nohup $JAVA_HOME/bin/jvisualvm --openjmx dtraflocorh187:30310 > /dev/null 2>&1 &"
alias jvvmSE11="nohup $JAVA_HOME/bin/jvisualvm --openjmx dtraflocorh184:30311 > /dev/null 2>&1 &"
alias jvvmSE12="nohup $JAVA_HOME/bin/jvisualvm --openjmx dtraflocorh184:54659 > /dev/null 2>&1 &"
alias jvvmSE14="nohup $JAVA_HOME/bin/jvisualvm --openjmx dtraflocorh183:30314 > /dev/null 2>&1 &"
alias jvvmSE15="nohup $JAVA_HOME/bin/jvisualvm --openjmx dtraflocorh187:30315 > /dev/null 2>&1 &"
alias jvvmSE16="nohup $JAVA_HOME/bin/jvisualvm --openjmx dtraflonrh674:30316 > /dev/null 2>&1 &"
alias jvvmSE17="nohup $JAVA_HOME/bin/jvisualvm --openjmx dtraflocorh187:30317 > /dev/null 2>&1 &"
alias jvvmSE20="nohup $JAVA_HOME/bin/jvisualvm --openjmx dtraflonrh674:54020 > /dev/null 2>&1 &"
alias jvvmSE21="nohup $JAVA_HOME/bin/jvisualvm --openjmx dtraflonrh671:54657 > /dev/null 2>&1 &"
alias jvvmSE24="nohup $JAVA_HOME/bin/jvisualvm --openjmx dtraflocorh210:54024 > /dev/null 2>&1 &"
alias jvvmSE25="nohup $JAVA_HOME/bin/jvisualvm --openjmx dtraflonrh674:30325 > /dev/null 2>&1 &"
alias jvvmSE27="nohup $JAVA_HOME/bin/jvisualvm --openjmx dtraflonrh894:30327 > /dev/null 2>&1 &"
alias jvvmSE28="nohup $JAVA_HOME/bin/jvisualvm --openjmx dtraflocorh230:30328 > /dev/null 2>&1 &"
alias jvvmSE30="nohup $JAVA_HOME/bin/jvisualvm --openjmx dtraflonrh671:30330 > /dev/null 2>&1 &"
alias jvvmSE31="nohup $JAVA_HOME/bin/jvisualvm --openjmx dtraflonrh894:30331 > /dev/null 2>&1 &"
alias jvvmSE32="nohup $JAVA_HOME/bin/jvisualvm --openjmx dtraflonrh671:30332 > /dev/null 2>&1 &"
alias jvvmSE33="nohup $JAVA_HOME/bin/jvisualvm --openjmx dtraflocorh183:30333 > /dev/null 2>&1 &"
alias jvvmSE34="nohup $JAVA_HOME/bin/jvisualvm --openjmx dtraflocorh230:30334 > /dev/null 2>&1 &"
alias jvvmSE37="nohup $JAVA_HOME/bin/jvisualvm --openjmx dtraflocorh184:30337 > /dev/null 2>&1 &"

alias devkins="ssh jenkins@starling-graylog.global.trafigura.com"
alias prodkins="ssh jenkins@jenkins-starling.global.trafigura.com"
