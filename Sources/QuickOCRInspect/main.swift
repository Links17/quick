import Foundation
import OnnxRuntimeBindings

struct ModelInspection {
    let path: String
    let inputs: [String]
    let outputs: [String]
}

func inspectModel(path: String) throws -> ModelInspection {
    let env = try ORTEnv(loggingLevel: ORTLoggingLevel.warning)
    let options = try ORTSessionOptions()
    try options.setIntraOpNumThreads(1)
    let session = try ORTSession(env: env, modelPath: path, sessionOptions: options)
    let inputs = try session.inputNames()
    let outputs = try session.outputNames()
    return ModelInspection(path: path, inputs: inputs, outputs: outputs)
}

let arguments = CommandLine.arguments.dropFirst()
let root = arguments.first ?? "AppBundle/Resources/OCR"
let modelPaths = [
    "\(root)/ppocrv6_tiny_det.onnx",
    "\(root)/ppocrv6_tiny_rec.onnx",
]

do {
    for modelPath in modelPaths {
        let inspection = try inspectModel(path: modelPath)
        print("model: \(inspection.path)")
        print("inputs: \(inspection.inputs.joined(separator: ","))")
        print("outputs: \(inspection.outputs.joined(separator: ","))")
    }
} catch {
    fputs("QuickOCRInspect failed: \(error.localizedDescription)\n", stderr)
    exit(1)
}
