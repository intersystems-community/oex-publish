Class OEX.GitHub Extends OEX.AbstractRepo
{

Parameter API = "api.github.com";

Method %OnNew(url As %String) As %Status
{
    if $Extract(url, *)'="/" {
        set url = url _ "/"
    }
    return ##super(url)
}

Method GetDefaultBranch() As %String
{
    set branch = "main"
    set ht = ..GetHTTPRequest()
    set path = ..Path
    if ($Extract(path,$Length(path))="/") {
        set path = $Extract(path,1,*-1)
    }
    set ht.Server = ..#API
    set ht.Location = "/repos"_path
    $$$ThrowOnError(ht.Get())
    if (ht.HttpResponse.StatusCode'=200) {
        $$$ThrowStatus($$$ERROR(5001,"Unable to get default branch"))
    }
    set jo = {}.%FromJSON(ht.HttpResponse.Data)
    set branch = jo."default_branch"
    return branch
}

Method DownloadPackage() As %String
{
    set branch = ..GetDefaultBranch()
    set ht = ..GetHTTPRequest()
    set ht.Location = ..Path_"archive/"_branch_".tar.gz"
    $$$ThrowOnError(ht.Get())
    do ##class(OEX.Utils).log("github download "_ht.Location_". Status: "_ht.HttpResponse.StatusCode)
    if (ht.HttpResponse.StatusCode'=200) {
        $$$ThrowStatus($$$ERROR(5001,"Unable to download repository "_..URL))
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
    set name = ..GetPackageNameFromRepositoryURL()
    return outputFolder_"/"_name_"-"_branch
}

Method GetPackageNameFromRepositoryURL() As %String
{
    return $piece(..URL, "/", *-1)
}

}
