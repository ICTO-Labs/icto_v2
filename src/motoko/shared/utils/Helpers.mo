// ⬇️ Shared Helper functions across all ICTO V2 services

import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Common "../types/Common";
import Blob "mo:base/Blob";
import Nat8 "mo:base/Nat8";
import Random "mo:base/Random";

module {
    // ================ KEY CREATION UTILITIES ================
    
    public func textKey(t: Text) : {key: Text; hash: Nat32} {
        {key = t; hash = Text.hash(t)}
    };
    
    public func principalKey(p: Principal) : {key: Principal; hash: Nat32} {
        {key = p; hash = Principal.hash(p)}
    };

    // ================ ID CREATION UTILITIES ================

    public func createProjectId(owner: Common.UserId, timestamp: Common.Timestamp) : Common.ProjectId {
        Principal.toText(owner) # "_" # Int.toText(timestamp)
    };
    
    public func createPipelineId(projectId: Common.ProjectId, timestamp: Common.Timestamp) : Common.PipelineId {
        projectId # "_pipeline_" # Int.toText(timestamp)
    };

    public func generateUUID() : async Text {
        let seed = await Random.blob();
        processbytes(seed)
    };

    private func processbytes(e : Blob) : Text {
        let bytes = Blob.toArrayMut(e);
        assert(bytes.size() >= 16);
        bytes[6] := (bytes[6] & 0x0F) | 0x40;
        bytes[8] := (bytes[8] & 0x3F) | 0x80;
        
        func byteToHex(byte : Nat8) : Text {
            let hexChars = ['0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'];
            let highNibble = byte >> 4;
            let lowNibble = byte & 0x0F;
            return Text.fromChar(hexChars[Nat8.toNat(highNibble)]) # Text.fromChar(hexChars[Nat8.toNat(lowNibble)]);
        };
        
        let uuid = byteToHex(bytes[0]) # byteToHex(bytes[1]) # byteToHex(bytes[2]) # byteToHex(bytes[3]) #
            "-" #
            byteToHex(bytes[4]) # byteToHex(bytes[5]) #
            "-" #
            byteToHex(bytes[6]) # byteToHex(bytes[7]) #
            "-" #
            byteToHex(bytes[8]) # byteToHex(bytes[9]) #
            "-" #
            byteToHex(bytes[10]) # byteToHex(bytes[11]) # byteToHex(bytes[12]) # byteToHex(bytes[13]) # byteToHex(bytes[14]) # byteToHex(bytes[15]);
        return uuid;
    };

} 