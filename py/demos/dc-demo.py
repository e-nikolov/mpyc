import asyncio
import json
from didcomm.common.types import DID, VerificationMethodType, VerificationMaterial, VerificationMaterialFormat
from didcomm.did_doc.did_doc import DIDDoc, VerificationMethod, DIDCommService
from didcomm.did_doc.did_resolver import DIDResolver
from didcomm.message import Message
from didcomm.secrets.secrets_resolver_demo import SecretsResolverDemo
from didcomm.unpack import unpack, UnpackResult
from didcomm.common.resolvers import ResolversConfig
from didcomm.pack_encrypted import pack_encrypted, PackEncryptedConfig, PackEncryptedResult
from didcomm.secrets.secrets_util import generate_x25519_keys_as_jwk_dict, generate_ed25519_keys_as_jwk_dict, jwk_to_secret
from peerdid import peer_did
from peerdid.did_doc import DIDDocPeerDID
from peerdid.types import VerificationMaterialAuthentication, VerificationMethodTypeAuthentication, VerificationMaterialAgreement, VerificationMethodTypeAgreement, VerificationMaterialFormatPeerDID
from peerdid.core.did_doc_types import DIDCommServicePeerDID

class DIDResolverPeerDID(DIDResolver):
    async def resolve(self, did: DID) -> DIDDoc:
        did_doc_json = peer_did.resolve_peer_did(did, format=VerificationMaterialFormatPeerDID.JWK)
        did_doc = DIDDocPeerDID.from_json(did_doc_json)

        return DIDDoc(
            did=did_doc.did,
            key_agreement_kids=did_doc.agreement_kids,
            authentication_kids=did_doc.auth_kids,
            verification_methods=[
                VerificationMethod(
                    id=m.id,
                    type=VerificationMethodType.JSON_WEB_KEY_2020,
                    controller=m.controller,
                    verification_material=VerificationMaterial(
                        format=VerificationMaterialFormat.JWK,
                        value=json.dumps(m.ver_material.value)
                    )
                )
                for m in did_doc.authentication + did_doc.key_agreement
            ],
            didcomm_services=[
                DIDCommService(
                    id=s.id,
                    service_endpoint=s.service_endpoint,
                    routing_keys=s.routing_keys,
                    accept=s.accept
                )
                for s in did_doc.service
                if isinstance(s, DIDCommServicePeerDID)
            ] if did_doc.service else []
        )


secrets_resolver = SecretsResolverDemo()


async def create_simple_peer_did() -> str:
    agreem_keys = generate_x25519_keys_as_jwk_dict()
    auth_keys = generate_ed25519_keys_as_jwk_dict()
    did = peer_did.create_peer_did_numalgo_2(
        [VerificationMaterialAgreement(
            type=VerificationMethodTypeAgreement.JSON_WEB_KEY_2020,
            format=VerificationMaterialFormatPeerDID.JWK,
            value=agreem_keys[1])
         ],
        [VerificationMaterialAuthentication(
            type=VerificationMethodTypeAuthentication.JSON_WEB_KEY_2020,
            format=VerificationMaterialFormatPeerDID.JWK,
            value=auth_keys[1])
         ],
        None
    )
    did_doc = DIDDocPeerDID.from_json(peer_did.resolve_peer_did(did))
    pk = auth_keys[0]
    pk["kid"] = did_doc.auth_kids[0]
    await secrets_resolver.add_key(jwk_to_secret(pk))
    private_key = agreem_keys[0]
    private_key["kid"] = did_doc.agreement_kids[0]
    await secrets_resolver.add_key(jwk_to_secret(private_key))

    return did


async def main():
    alice_did = await create_simple_peer_did()
    bob_did = await create_simple_peer_did()
    print("Alice's DID:", alice_did)
    print("Bob's DID:", bob_did)

asyncio.run(main())
