#!/usr/bin/env python3

import json
import sys
import os.path
import fnmatch

def add_ricardian_contracts_to_actions(source_abi_directory, contract_name, abi_actions):
    abi_actions_with_ricardian_contracts = []

    for abi_action in abi_actions:
        action_name = abi_action["name"]
        contract_action_filename = '{contract_name}-{action_name}-rc.md'.format(contract_name = contract_name, action_name = action_name)

        # check for rc file
        rc_contract_path = os.path.join(source_abi_directory, contract_action_filename)
        if os.path.exists(rc_contract_path):
            print('Importing Contract {contract_action_filename} for {contract_name}:{action_name}'.format(
                contract_action_filename = contract_action_filename,
                contract_name = contract_name,
                action_name = action_name
            ))

            with open(rc_contract_path, encoding="utf8") as contract_file_handle:
                contract_contents = contract_file_handle.read()

            abi_action['ricardian_contract'] = contract_contents
        else:
            print('Did not find Ricardian Contract file {contract_action_filename} for {contract_name}:{action_name}, skipping inclusion'.format(
                contract_action_filename = contract_action_filename,
                contract_name = contract_name,
                action_name = action_name
            ))

        abi_actions_with_ricardian_contracts.append(abi_action)

    return abi_actions_with_ricardian_contracts

def create_ricardian_clauses_list(source_abi_directory, contract_name):
    clause_file_pattern = '*-clause*-rc.md'
    clause_files = fnmatch.filter(os.listdir(source_abi_directory), clause_file_pattern)

    clause_prefix = 'clause-'
    clause_postfix = '-rc.md'

    abi_ricardian_clauses = []

    for clause_file_name in clause_files:
        rc_contract_path = os.path.join(source_abi_directory, clause_file_name)
        with open(rc_contract_path, encoding="utf8") as contract_file_handle:
            contract_contents = contract_file_handle.read()

        start_of_clause_id = clause_file_name.index( clause_prefix ) + len( clause_prefix )
        end_of_clause_id = clause_file_name.rindex(clause_postfix, start_of_clause_id)

        clause_id = clause_file_name[start_of_clause_id:end_of_clause_id]

        abi_ricardian_clauses.append({
            'id': clause_id,
            'body': contract_contents
        })

    return abi_ricardian_clauses

def add_ricardian_contracts_to_abi(source_abi, output_abi):
    source_abi_directory = os.path.dirname(source_abi)
    contract_name = os.path.split(source_abi)[1].rpartition(".")[0]

    print('Creating {output_abi} with ricardian contracts included'.format(output_abi = output_abi))

    with open(source_abi, 'r', encoding="utf8") as source_abi_file:
        source_abi_json = json.load(source_abi_file)

    source_abi_json['actions'] = add_ricardian_contracts_to_actions(source_abi_directory, contract_name, source_abi_json['actions'])
    source_abi_json['ricardian_clauses'] = create_ricardian_clauses_list(source_abi_directory, contract_name)

    with open(output_abi, 'w', encoding="utf8") as output_abi_file:
        json.dump(source_abi_json, output_abi_file, indent=2)

def import_ricardian_to_abi(abi_file):
    if not os.path.exists(abi_file):
        print('Source ABI not found in {abi_file}'.format(abi_file=abi_file))
        sys.exit(0)

    add_ricardian_contracts_to_abi(abi_file, abi_file)

def main():
    if len(sys.argv) != 2:
        print('Please specify a source abi, which will be overwritten:')
        print('Usage: ./ricardeos.py /eos/contracts/contract/mycontract.abi')
    else:
        import_ricardian_to_abi(sys.argv[1])

if __name__ == '__main__':
        main()
