#pragma once

#include <algorithm>
#include <string>

#include <eosiolib/eosio.hpp>
#include <eosiolib/asset.hpp>
#include <eosiolib/time.hpp>
#include <eosiolib/transaction.hpp>

using eosio::asset;
using eosio::const_mem_fun;
using eosio::indexed_by;
using eosio::name;
using eosio::time_point_sec;
using std::function;
using std::string;

class battlefield : public eosio::contract {
    public:
        battlefield(account_name self)
        :eosio::contract(self)
        {}


        // @abi
        void dbins(account_name account);
        void dbupd(account_name account);
        void dbrem(account_name account);
        void dtrx(account_name account, bool fail);
        void dtrxcancel(account_name account);
        void dtrxexec(account_name account);


    private:
        // 6 months in seconds (Computation: 6 months * average days per month * 24 hours * 60 minutes * 60 seconds)
        constexpr static uint32_t SIX_MONTHS_IN_SECONDS = (uint32_t) (6 * (365.25 / 12) * 24 * 60 * 60);

        struct member_row {
            uint64_t              id;
            account_name          account;
            asset                 amount;
            string                memo;
            time_point_sec        created_at;
            time_point_sec        expires_at;

            auto primary_key()const { return id; }
            uint64_t by_account() const { return account; }

            bool is_expired() const { return time_point_sec(now()) >= expires_at; }
        };
        typedef eosio::multi_index<
            N(member), member_row,
            indexed_by<N(byaccount), const_mem_fun<member_row, account_name, &member_row::by_account>>
        > members;
};
