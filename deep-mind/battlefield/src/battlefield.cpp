#include "battlefield.hpp"
#include <eosiolib/eosio.hpp>
#include <eosiolib/asset.hpp>
#include <eosiolib/transaction.hpp>
#include <eosiolib/action.hpp>

extern "C" {
    void apply(uint64_t receiver, uint64_t code, uint64_t action) {
        if (code == receiver) {
            switch (action) {
                EOSIO_DISPATCH_HELPER(battlefield, (dbins)(dbinstwo)(dbupd)(dbrem)(dtrx)(dtrxcancel)(dtrxexec)(creaorder)(inlineempty)(inlinedeep))
            }
        } else {
            switch (action) {
                EOSIO_DISPATCH_HELPER(battlefield, (creaorder))
            }
        }
    }
}

[[eosio::action]]
void battlefield::dbins(name account) {
    require_auth(account);

    eosio::print("dbins ran and you're authenticated");

    members member_table(_self, _self.value);
    member_table.emplace(account, [&](auto& row) {
        row.id = 1;
        row.account = "dbops1"_n;
        row.memo = "inserted billed to calling account";
        row.created_at = time_point_sec(now());
    });

    member_table.emplace(_self, [&](auto& row) {
        row.id = 2;
        row.account = "dbops2"_n;
        row.memo = "inserted billed to self";
        row.created_at = time_point_sec(now());
    });
}

[[eosio::action]]
void battlefield::dbinstwo(name account, uint64_t first, uint64_t second) {
    require_auth(account);

    members member_table(_self, _self.value);
    member_table.emplace(account, [&](auto& row) {
        row.id = first;
        row.account = name(first);
        row.memo = "inserted billed to calling account";
        row.created_at = time_point_sec(now());
    });

    member_table.emplace(_self, [&](auto& row) {
        row.id = second;
        row.account = name(second);
        row.memo = "inserted billed to self";
        row.created_at = time_point_sec(now());
    });
}

[[eosio::action]]
void battlefield::dbupd(name account) {
    require_auth(account);

    members member_table(_self, _self.value);
    auto index = member_table.template get_index<"byaccount"_n>();
    auto itr1 = index.find("dbops1"_n.value);
    auto itr2 = index.find("dbops2"_n.value);

    index.modify(itr1, _self, [&](auto& row) {
        row.memo = "updated row 1";
    });

    index.modify(itr2, account, [&](auto& row) {
        row.account = "dbupd"_n;
        row.memo = "updated row 2";
    });
}

[[eosio::action]]
void battlefield::dbrem(name account) {
    require_auth(account);

    members member_table(_self, _self.value);
    auto index = member_table.template get_index<"byaccount"_n>();
    index.erase(index.find("dbops1"_n.value));
    index.erase(index.find("dbupd"_n.value));
}

[[eosio::action]]
void battlefield::dtrx(
    name account,
    bool fail_now,
    bool fail_later,
    uint32_t delay_sec,
    string nonce
) {
    require_auth(account);

    eosio::transaction deferred;
    uint128_t sender_id = (uint128_t(0x1122334455667788) << 64) | uint128_t(0x1122334455667788);
    deferred.actions.emplace_back(
        eosio::permission_level{_self, "active"_n},
        _self,
        "dtrxexec"_n,
        std::make_tuple(account, fail_later, nonce)
    );
    deferred.delay_sec = delay_sec;
    deferred.send(sender_id, account, true);

    eosio_assert(!fail_now, "forced fail as requested by action parameters");
}

[[eosio::action]]
void battlefield::dtrxcancel(name account) {
    require_auth(account);

    uint128_t sender_id = (uint128_t(0x1122334455667788) << 64) | uint128_t(0x1122334455667788);
    cancel_deferred(sender_id);
}

[[eosio::action]]
void battlefield::dtrxexec(name account, bool fail, std::string nonce) {
  require_auth(account);
  eosio_assert(!fail, "dtrxexec instructed to fail");
}

[[eosio::action]]
void battlefield::creaorder(name n1, name n2, name n3, name n4, name n5) {
    if (_self == _code) {
        // We are the root action (a1), let's notify n1, n2 and send i5
        require_recipient(n1);
        require_recipient(n2);

        inlinedeep_action i5(_code, {_self, "active"_n});
        i5.send(string("i5"), n4, n5, string("i6"), false);
    } else if (_self == n2) {
        // We are actually dealing with the notification of n2, send i4 and notify n3
        inlineempty_action i4(_code, {_self, "active"_n});
        i4.send(string("i4"), false);

        require_recipient(n3);
    }
}

[[eosio::action]]
void battlefield::inlineempty(string tag, bool fail) {
    eosio_assert(!fail, "inlineempty instructed to fail");
}

[[eosio::action]]
void battlefield::inlinedeep(string tag, name n4, name n5, string nestedInlineTag, bool nestedInlineFail) {
    require_recipient(n4);
    require_recipient(n5);

    inlineempty_action nested(_code, {_self, "active"_n});
    nested.send(nestedInlineTag, nestedInlineFail);
}
