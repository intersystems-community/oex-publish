Class OEX.Publisher
{

/// Description
ClassMethod Publish(url) As %Status
{
    try {
        set repo = ##class(AbstractRepo).getService(url)
        if ('$isobject(repo)) {
            $$$ThrowStatus($$$ERROR(5001,"Only github.com or gitlab.com are supported"))
        }

        set packageFolder = repo.DownloadPackage()

        If '##class(%File).Exists(packageFolder_"/module.xml") {
            $$$ThrowStatus($$$ERROR(5001,"file `module.xml` doesn't exist"))
        }
        set modulexmlname = ..GetModuleNameFromXML(packageFolder_"/module.xml")

        $$$ThrowOnError(..IPMPublish(modulexmlname, packageFolder))

        $$$ThrowOnError(..DeletePackageFolder(packageFolder))
    } catch ex {
        do ex.Log()
        throw ex
    }
    return $$$OK
}

ClassMethod IPMPublish(moduleName As %String, moduleFolder) As %Status
{
    set tSC = $$$OK
    set filename = ##class(%File).TempFilename("txt")
    open filename:("NRW"):1
    use filename
    try {
        set registry = ##class(%SYSTEM.Util).GetEnviron("REGISTRY")
        set registryUser = ##class(%SYSTEM.Util).GetEnviron("REGISTRYUSER")
        set registryPass = ##class(%SYSTEM.Util).GetEnviron("REGISTRYPASS")

        $$$ThrowOnError($zpm("repo -n registry -r -url https://pm.community.intersystems.com/ -user """" -pass """""))
        $$$ThrowOnError($zpm("load " _ moduleFolder))
        $$$ThrowOnError($zpm("repo -n registry -r -url "_registry_" -user """_registryUser_""" -pass """_registryPass_""""))
        $$$ThrowOnError($zpm("publish " _ moduleName))
        $$$ThrowOnError($zpm("uninstall " _ moduleName _ " -recurse"))

    } catch ex {
        set tSC = ex.AsStatus()
    }
    close filename:"D"
    return tSC
}

ClassMethod GetModuleNameFromXML(filename As %String) As %String
{
    set stream = ##class(%Stream.FileBinary).%New()
    set sc = stream.LinkToFile(filename)

    set xPathArray("Module/Name")=""
    $$$ThrowOnError(##class(OEX.Utils).ReadXMLElements(stream, .xPathArray))
    return $Get(xPathArray("Module/Name","text"))
}

ClassMethod DeletePackageFolder(path As %String) As %Status
{
    if ( '##class(%File).RemoveDirectoryTree(path) ) {
        return $$$ERROR(5001, "Error during the clean up")
    }
    return $$$OK
}

}
