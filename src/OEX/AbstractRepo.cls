Class OEX.AbstractRepo Extends %RegisteredObject
{

Property URL As %String;

Property Host As %String;

Property Https As %Boolean;

Property Path As %String;

Property Port As %String;

Method %OnNew(url) As %Status
{
    set ..URL = url
    do ##class(%Net.URLParser).Decompose(..URL, .tComponents)
    set ..Host = tComponents("host")
    set ..Https = 0
    if $get(tComponents("scheme"))="https" {
        set ..Https = 1
    }
    set ..Port = $get(tComponents("port"))
    set ..Path = $get(tComponents("path"))

    return $$$OK
}

ClassMethod getService(url As %String) As AbstractRepo
{
    if ($find(url, "gitlab.com/") '= 0) {
        return ##class(OEX.GitLab).%New(url)
    } elseif ($find(url, "github.com/") '= 0){
        return ##class(OEX.GitHub).%New(url)
    } else {
        return $$$NULLOREF
    }
}

Method DownloadPackage() As %String [ Abstract ]
{
}

Method GetHTTPRequest() As %Net.HttpRequest
{
    set ht = ##class(%Net.HttpRequest).%New()
    set ht.Server = ..Host
    if (..Https) {
        set ht.SSLConfiguration = ##class(OEX.Utils).GetSSLConfiguration(ht.Server)
        set ht.Https = 1
    }
    if ..Port="" {
        set ht.Port = ..Port
    }
    return ht
}

}
