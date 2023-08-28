Class OEX.REST Extends %CSP.REST
{

Parameter CHARSET = "utf-8";

Parameter CONTENTTYPE = "application/json";

Parameter HandleCorsRequest = 1;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <!-- Server Info -->
    <Route Url="/publish" Method="POST" Call="Publish" Cors="true"/>
    <Route Url="/_ping" Method="GET" Call="Ping" Cors="true"/>
</Routes>
}

ClassMethod Ping() As %Status
{
    set pong = {
        "message": "ping"
    }
    write pong.%ToJSON()
    return $$$OK
}

ClassMethod Publish() As %Status
{
    set %response.Timeout = 180

    try {
        set request = ##class(%Library.DynamicObject).%FromJSON(%request.Content)
        if (request.repo = "") {
            $$$ThrowStatus($$$ERROR(5001, "Invalid request: `repo` required"))
        }
        $$$ThrowOnError(##class(OEX.Publisher).Publish(request.repo))
    } catch ex {
        return ex.AsStatus()
    }
    write {}.%ToJSON()
    return $$$OK
}

}
