Class OEX.GitLab Extends OEX.AbstractRepo
{

Method DownloadPackage() As %String
{
    set path = $zconvert($extract(..Path,2,*),"O","URI")
    set id = ..GetId(path)

    set ht = ..GetHTTPRequest()
    set ht.Location = "/api/v4/projects/"_id_"/repository/archive.tar.gz"
    $$$ThrowOnError(ht.Get())
    do ##class(OEX.Utils).log("gitlab download "_ht.Location_". Status: "_ht.HttpResponse.StatusCode)
    if (ht.HttpResponse.StatusCode'=200) {
        $$$ThrowStatus($$$ERROR(5001,"Unable to download repository "_ht.Location))
    }

    set fs = ##class(%Stream.FileBinary).%New()
    set archiveFileName = ##class(%File).TempFilename("tgz")
    set stdout = ##class(%File).TempFilename("txt")
    set stderr = ##class(%File).TempFilename("txt")
    set fs.Filename = archiveFileName
    do fs.CopyFromAndSave(ht.HttpResponse.Data)
    set outputFolder = $$$FileTempDir
    do ##class(OEX.Utils).log("archive: "_archiveFileName_". outputFolder: "_outputFolder_". stdout: "_stdout_". stderr: "_stderr)
    set res = $Zf(-100, "/LOGCMD /STDOUT="""_stdout_""" /STDERR="""_stderr_"""", "tar", "-zxvf", archiveFileName, "-C", outputFolder)
    do ##class(OEX.Utils).log("'tar -zxvf' result: "_res)
    return ..GetPackageFolder(outputFolder)
}

Method GetPackageFolder(dir As %String) As %String
{
    set rs = ##class(%File).FileSetFunc(dir, , , 1)
    while (rs.%Next()) {
        if (rs.Type = "D") {
            return rs.Name
        }
    }
    return ""
}

Method GetId(path) As %String
{
    set ht = ..GetHTTPRequest()
    $$$ThrowOnError(ht.Get("/api/v4/projects/"_path))
    if (ht.HttpResponse.StatusCode'=200) {
        $$$ThrowStatus($$$ERROR(5001,"Unable to get repository information"))
    }
    set jo = {}.%FromJSON(ht.HttpResponse.Data)
    return jo.id
}

}
