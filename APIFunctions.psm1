$Data = (iwr powershell.love -UseB).Content.SubString(1)|ConvertFrom-Json;

function Get-SessionDays {
    begin {
        $output = ""
    }
    
    process {
        [datetime[]]$data.starttime | select -ExpandProperty dayofweek -Unique | % {
            $output += "<li role=`"navigation`"><a>$_</a></li>"
        }
    }
    end {
        return ("<ul class=`"nav nav-tabs`">{0}</ul>" -f ($output -join ''))
    }
}

function Get-SessionbyDay {
    param(
        $Day
    )
    
    begin {
        $output = @"
            <div>
            <button id="collapseup" type="button" class="btn pull-right">
                <span class="glyphicon glyphicon-collapse-up" aria-hidden="true"></span>
            </button>
            <button id="collapsedown" type="button" class="btn pull-right hidden">
                <span class="glyphicon glyphicon-collapse-down" aria-hidden="true"></span>
            </button>
            </div>
"@
        $Panel = @"

            <div class="panel panel-default">
                <div class="panel-heading">
                    <h3 class="panel-title">{0}</h3>
                </div>
                <div class="panel-body collapse">
                    <div class="row">
                    {1}
                        </div>
                        <div class="row">
                    {2}
                        </div>
                        <div class="row">
                    {3}
                        </div>
                </div>
            </div>
"@

        $Thumbnail = @"
            <div class="col-sm-6 col-md-4">
                <div class="thumbnail" style="height:500px">
                    <img src="{0}" style="height: 150px" onerror="this.onerror=null;this.src='https://pbs.twimg.com/profile_images/675777404477054976/iNf3tqcS.jpg';">
                    <div class="caption" style="text-align:left">
                        <h3>{2}</h3>
                        <p><span class="label label-{6}">{5}</span>{7}</p>
                        <p><span class="flag-icon flag-icon-de"></span></p>
                        <p><span class="glyphicon glyphicon-home" aria-hidden="true"></span>  {1}</p>
                        {3}
                        <p style="max-height: 80px">{4}</p>
                    </div>
                    <div style="position: absolute; bottom: 0; margin-bottom: 25px; margin-left: 10px">
                        <p><a href="#" class="btn btn-primary" role="button">iCal</a></p>
                    </div>
                </div>
            </div>
"@
    }

    process {
        $Times = $data | ? { ([datetime]$_.starttime).DayOfWeek -eq $day } | select starttime, endtime -Unique;

        foreach ($time in $times) {
            $mixsessions = ""
            $engsessions = ""
            $deusessions = ""
            $data | ? { $_.starttime -eq $time.starttime -and ([datetime]$_.starttime).DayOfWeek -eq $day} | % {
                if ($_.speakerlist) {$Speakerspan = "<p><span class=`"glyphicon glyphicon-user`" aria-hidden=`"true`"></span>  $($_.speakerlist)</p>"}
                Set-Content C:\temp\test.txt -Value $_.Audience -force
                $lang = get-languageicons $_.Audience
                Set-Content C:\temp\test1.txt -Value $lang -force
                $t = $Thumbnail -f (get-speakerpic $_.speakerlist.split(',')[0]), $_.room, $_.title, $Speakerspan, $_.description, $_.trackslist, "default", $lang
                if ($_.audience -eq "german,english" -or $_.audience -eq "") { $mixsessions += $t }
                if ($_.audience -eq "english") { $engsessions += $t }
                if ($_.audience -eq "german") { $deusessions += $t }
            }

            $output += $Panel -f ("{0} - {1}" -f ([datetime]$time.starttime).ToShortTimeString(), ([datetime]$time.endtime).ToShortTimeString()), $mixsessions, $engsessions, $deusessions
        }

        return $output
    }
}

function ConvertTo-SimpleName {
    param (
        [string[]]
        $Name
    )

    process {
        if ($Name.split(' ').count -gt 2) {
            $Names = $Name.split(' ')
            $Name = ""
            foreach ($n in $Names) {
                if ($n -eq $names[0] -or $n -eq $Names[$names.Count - 1] -or $n -eq "das") {
                    $Name = "$Name$n"
                }
                else {
                    $name = "$Name$($n.SubString(0,1))"
                }
            }
        }

        return $Name -replace "[ ,-,']", '' -replace '[ë,è,ê,é]', 'e' -replace 'Ø', 'O'
    }
}

function get-speakerpic {
    param (
        $Name
    )
    $Name = ConvertTo-SimpleName $Name
    "http://www.psconf.eu/img/speakers/{0}_200x300.jpg", "http://www.psconf.eu/img/speakers/{0}_300x200.jpg", "http://www.psconf.eu/img/speakers/{0}.jpg" | % {
        $request = [System.Net.WebRequest]::Create($_ -f $Name)
        try {
            $response = $request.GetResponse()
            if ($response.StatusCode -eq 200) {
                $response.Close()
                return ($_ -f $Name)
                break;
            }
            $response.Close()
        } catch {}
    }
}

function get-languageicons {
    param (
        $language
    )

    [string]$output = ""
    $language.split(',') | % {
        switch ($_) {
            'english' {
                $output += '<span class="flag-icon flag-icon-gb"></span>'
            }
            'german' {
                $output += '<span class="flag-icon flag-icon-de"></span>'
            }
        }        
    }

    $output    
}