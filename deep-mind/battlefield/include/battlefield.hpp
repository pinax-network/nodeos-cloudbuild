#pragma once

#include <algorithm>
#include <string>

#include <eosiolib/eosio.hpp>
#include <eosiolib/asset.hpp>
#include <eosiolib/time.hpp>
#include <eosiolib/transaction.hpp>

using eosio::action_wrapper;
using eosio::asset;
using eosio::contract;
using eosio::const_mem_fun;
using eosio::datastream;
using eosio::indexed_by;
using eosio::name;
using eosio::time_point_sec;
using std::function;
using std::string;

class [[eosio::contract("battlefield")]] battlefield : public contract {
    public:
        battlefield(name receiver, name code, datastream<const char*> ds)
        :contract(receiver, code, ds)
        {}

        [[eosio::action]]
        void dbins(name account);

        [[eosio::action]]
        void dbinstwo(name account, uint64_t first, uint64_t second);

        [[eosio::action]]
        void dbupd(name account);

        [[eosio::action]]
        void dbrem(name account);

        [[eosio::action]]
        void dtrx(
            name account,
            bool fail_now,
            bool fail_later,
            uint32_t delay_sec,
            string nonce
        );

        [[eosio::action]]
        void dtrxcancel(name account);

        [[eosio::action]]
        void dtrxexec(name account, bool fail, string nonce);

        /**
         * We are going to replicate the following creation order:
         *
         * ```
         * (Legend: a - Root Action, n - Notification (require_recipient), i - Inline (send_inline))
         *   a1
         *   ├── n1
         *   ├── n2
         *   |   ├── i4
         *   |   └── n3
         *   └── i5
         *       ├── n4
         *       ├── n5
         *       └── i6
         * ```
         *
         * Consumer will pass the following information to create the hierarchy:
         *  - n1 The account notified in n1, must not have a contract
         *  - n2 The account notified in n2, must be an account with the
         *       battlefield account installed on it. Will accept the notification
         *       and will create i4 and n3.
         *  - n3 The account notified in n3, must not have a contract, accessible
         *       through the notificiation of n2 (same context).
         *  - n4 The account notified in N4, must not have a contract
         *  - n5 The account notified in N5, must not have a contract
         *
         * The i4 and i6 will actually execute `inlineempty` with a tag of `"i4"`
         * and `"i6"` respectively.
         *
         * The i5 will actually `require_recipient(n4)` and
         * `require_recipient(n5)` followed by a `inlineempty` with a tag of
         * `"i5"`.
         */
        [[eosio::action]]
        void creaorder(name n1, name n2, name n3, name n4, name n5);

        [[eosio::action]]
        void inlineempty(string tag, bool fail);

        [[eosio::action]]
        void inlinedeep(string tag, name n4, name n5, string nestedInlineTag, bool nestedInlineFail);

        // Inline action wrappers (so we can construct them in code)
        using inlineempty_action = action_wrapper<"inlineempty"_n, &battlefield::inlineempty>;
        using inlinedeep_action = action_wrapper<"inlinedeep"_n, &battlefield::inlinedeep>;

    private:

        struct [[eosio::table]] member_row {
            uint64_t id;
            name account;
            asset amount;
            string memo;
            time_point_sec created_at;
            time_point_sec expires_at;

            auto primary_key()const { return id; }
            uint64_t by_account() const { return account.value; }
        };

        typedef eosio::multi_index<
            "member"_n, member_row,
            indexed_by<"byaccount"_n, const_mem_fun<member_row, uint64_t, &member_row::by_account>>
        > members;
};
