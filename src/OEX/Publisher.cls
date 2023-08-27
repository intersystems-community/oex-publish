Class OEX.Publisher
{

ClassMethod GetTmpName(tmpFolder As %String) As %String
{
    return $zconvert($piece(tmpFolder,"/", $length(tmpFolder,"/")),"U")
}

ClassMethod DropDBandNS(name As %String) As %Status
{
    new $namespace
    set $namespace = "%SYS"

    try {

        set dir = ##class(%SYSTEM.Util).InstallDirectory()_"mgr/"_name
        // namespace
        $$$ThrowOnError(##class(Config.Namespaces).Delete(name))

        //database and files
        $$$ThrowOnError(##class(Config.Databases).Delete(name))
        $$$ThrowOnError(##class(SYS.Database).DeleteDatabase(dir))

        set result = ##class(%File).RemoveDirectoryTree(dir) // 0/1
        if (result = 0) {
            $$$ThrowStatus($$$ERROR(5001, "unable to delete directory"))
        }

        // find all webapp for specified namespace
        set statement = ##class(%SQL.Statement).%New()
        $$$ThrowOnError(statement.%PrepareClassQuery("Security.Applications", "List"))

        set row = statement.%Execute("*")
        while row.%Next(.tSC) {
            $$$ThrowOnError(tSC)
            if ( (row.%Get("Namespace")=name) && (row.%Get("Type") = "CSP") ) {
                $$$ThrowOnError(##class(Security.Applications).Delete(row.%Get("Name")))
            }
        }
    } catch ex {
        return ex.AsStatus()
    }
    return $$$OK
}

ClassMethod CreateDBandNS(name As %String) As %Status
{
    new $namespace
    set $namespace = "%SYS"

    try {
        set dir = ##class(%SYSTEM.Util).InstallDirectory()_"mgr/"_name
        set result = ##class(%File).CreateDirectoryChain(dir)
        if (result = 0) {
            $$$ThrowStatus($$$ERROR(5001, "unable to create directory"))
        }

        set db = ##Class(SYS.Database).%New()
        set db.Directory = dir
        $$$ThrowOnError(db.%Save())

        set properties("Directory") = dir
        $$$ThrowOnError(##Class(Config.Databases).Create(name, .properties))

        /// Create Namespace
        //DB for globals
        set nsProperties("Globals") = name
        //DB for routines
        set nsProperties("Routines") = name
        $$$ThrowOnError(##Class(Config.Namespaces).Create(name,.nsProperties))
    } catch ex {
        return ex.AsStatus()
    }

    return $$$OK
}

/// Description
ClassMethod test(url) As %Status
{
    if $Extract(url, *)'="/" {
        set url = url _ "/"
    }

    try {
        // скачать целиком архив
        set outputFolder = ..DownloadPackageFromGitHub(url, .projectFolder)

        w !,outputFolder
        w !,projectFolder

        set stream=##class(%Stream.FileBinary).%New()
        Set sc = stream.LinkToFile(outputFolder_"/"_projectFolder_"/module.xml")

        set xPathArray("Module/Name")=""
        $$$ThrowOnError(##class(OEX.Utils).ReadXMLElements(stream, .xPathArray))
        set modulexmlname = $Get(xPathArray("Module/Name","text"))

        w !,modulexmlname

        return 1

        set tmpNS = ..GetTmpName(outputFolder)

        w !,tmpNS

        set st = ..CreateDBandNS(tmpNS)

        do ..Publish(tmpNS, modulexmlname, outputFolder_"/"_projectFolder)

        set st = ..DropDBandNS(tmpNS)

    } catch ex {
        zw ex
    }
    return 1
}

ClassMethod Publish(ns As %String, moduleName As %String, moduleFolder) As %Status
{
    new $namespace
    set $namespace = ns
    try {

        $$$ThrowOnError($zpm("load " _ moduleFolder))
        $$$ThrowOnError($zpm("repo -n registry -r -url https://test.pm.community.intersystems.com/registry/ -user test -pass PassWord42"))
        $$$ThrowOnError($zpm("publish " _ moduleName))
        $$$ThrowOnError($zpm("uninstall " _ moduleName _ " -recurse"))

    } catch ex {
        w !!
        w "ERR"
        w ex.DisplayString()
    }

    return 1
}

ClassMethod GetHTTPRequest(url As %String, Output tComponents) As %Net.HttpRequest
{
    do ##class(%Net.URLParser).Decompose(url, .tComponents)
    set ht = ##class(%Net.HttpRequest).%New()
    set ht.Server = tComponents("host")
    if $Get(tComponents("scheme"))="https" {
        set ht.SSLConfiguration = ##class(OEX.Utils).GetSSLConfiguration(ht.Server)
        set ht.Https = 1
    }
    if $Data(tComponents("port"), port), port'="" {
        set ht.Port = port
    }
    return ht
}

ClassMethod GetGitHubDefaultBranch(url As %String) As %String
{
    set branch = "main"
    set ht = ..GetHTTPRequest(url, .tComponents)
    set path = tComponents("path")
    if ($Extract(path,$Length(path))="/") {
        set path = $Extract(path,1,*-1)
    }
    set ht.Server = "api.github.com"
    set ht.Location = "/repos"_path
    $$$ThrowOnError(ht.Get())
    if (ht.HttpResponse.StatusCode=200) {
        set jo = {}.%FromJSON(ht.HttpResponse.Data)
        set branch = jo."default_branch"
    }
    return branch
}

ClassMethod GetPackageNameFromRepositoryURL(url As %String) As %String
{
    return $piece(url, "/", *-1)
}

ClassMethod DownloadPackageFromGitHub(url, Output projectFolder As %String) As %String
{
    set branch = ..GetGitHubDefaultBranch(url)
    set ht = ..GetHTTPRequest(url, .tComponents)
    set ht.Location = tComponents("path")_"archive/"_branch_".tar.gz"
    $$$ThrowOnError(ht.Get())
    if (ht.HttpResponse.StatusCode'=200) {
        $$$ThrowStatus($$$ERROR(5001,"Unable to download repository "_url))
    }
    set fs = ##class(%Stream.FileBinary).%New()
    set archiveFileName = ##class(%File).TempFilename("tgz")
    set fs.Filename = archiveFileName
    do fs.CopyFromAndSave(ht.HttpResponse.Data)
    set outputFolder = $$$FileTempDir
    set res = $Zf(-100, "", "tar", "-zxvf", archiveFileName, "-C", outputFolder)
    set name = ..GetPackageNameFromRepositoryURL(url)
    set projectFolder = name_"-"_branch
    return outputFolder
}

ClassMethod downloadFromGitLab()
{
 //https://community.intersystems.com/post/how-create-new-database-namespace-and-web-application-intersystems-iris-programmatically
 // создать область и бд

 /*
    https://gitlab.com/api/v4/projects/nsolov%2Ftest1

    https://gitlab.com/api/v4/projects/47931365/repository/archive.zip

    unzip
    https://askubuntu.com/questions/86849/how-to-unzip-a-zip-file-from-the-terminal
 */
}

ClassMethod GetModuleMeta(url As %String) As %DynamicObject
{
  Set jo = {"name":"", "version":""}
  Do ##class(%Net.URLParser).Parse(url, .tComponents)
  Set ht = ##class(%Net.HttpRequest).%New()
  Set ht.Server = "raw.githubusercontent.com"
  If $Get(tComponents("scheme"))="https" {
    Set ht.SSLConfiguration = ##class(OEX.Utils).GetSSLConfiguration(ht.Server)
    Set ht.Https = 1
  }
  If $Data(tComponents("port"), port), port'="" {
    Set ht.Port = port
  }
  Set ht.Location = tComponents("path")_"master/module.xml"
  $$$ThrowOnError(ht.Get())
  If (ht.HttpResponse.StatusCode'=200) {
    $$$ThrowStatus($$$ERROR(5001,"Unable to download XML "_ht.Location))
  }

  Set xPathArray("Module/Version")=""
  Set xPathArray("Module/Name")=""

  $$$ThrowOnError(##class(OEX.Utils).ReadXMLElements(ht.HttpResponse.Data, .xPathArray))

  Set jo.name = $Get(xPathArray("Module/Name","text"))
  Set jo.version = $Get(xPathArray("Module/Version","text"))

  Return jo
}

}
