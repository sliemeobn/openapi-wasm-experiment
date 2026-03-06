import HTTPTypes
import JavaScriptKit
import OpenAPIRuntime

#if canImport(FoundationEssentials)
    import struct FoundationEssentials.URL
#else
    import struct Foundation.URL
#endif

// UNTESTED TOY IMPLEMENTATION, DO NOT USE
struct JSFetchClientTransport: ClientTransport {
    func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let url = baseURL.appending(path: request.path ?? "")

        let options = JSObject()
        options["method"] = request.method.rawValue.jsValue
        options["headers"] = makeHeaders(request.headerFields).jsValue

        if let body {
            let bytes = try await [UInt8](collecting: body, upTo: .max)
            options["body"] = JSTypedArray<UInt8>(bytes).jsValue
        }

        let fetchPromise = JSPromise(
            unsafelyWrapping: JSObject.global.fetch!(url.absoluteString, options).object!)
        let response = try await fetchPromise.value.object!
        let status = Int(response["status"].number!)
        let statusText = response["statusText"].string ?? ""

        var headers = HTTPFields()
        let jsHeaders = response["headers"].object!
        let closure = JSClosure { args in
            headers.append(HTTPField(name: .init(args[1].string!)!, value: args[0].string!))
            return .undefined
        }
        jsHeaders["forEach"].function!(this: jsHeaders, closure)

        let arrayBuffer = try await JSPromise(
            unsafelyWrapping: response.arrayBuffer!().object!
        ).value

        let uint8Array = JSTypedArray<UInt8>(
            unsafelyWrapping: JSObject.global.Uint8Array.function!.new(arrayBuffer.object!))

        let bytes = [UInt8](unsafeUninitializedCapacity: uint8Array.lengthInBytes) {
            buffer, count in
            uint8Array.copyMemory(to: buffer)
            count = uint8Array.lengthInBytes
        }

        return (
            HTTPResponse(
                status: .init(code: status, reasonPhrase: statusText), headerFields: headers),
            bytes.isEmpty ? nil : HTTPBody(bytes)
        )
    }

    private func makeHeaders(_ fields: HTTPFields) -> JSObject {
        let headers = JSObject.global.Headers.function!.new()
        for field in fields {
            _ = headers.append!(field.name.rawName, field.value)
        }
        return headers
    }
}
