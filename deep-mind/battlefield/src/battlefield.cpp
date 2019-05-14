#include "battlefield.hpp"

void battlefield::dbins(name account) {
    require_auth(account);

    print("dbins ran and you're authenticated");

    members member_table(_self, _self.value);
    member_table.emplace(account, [&](auto& row) {
        row.id = 1;
        row.account = "dbops1"_n;
        row.memo = "inserted billed to calling account";
        row.created_at = time_point_sec(current_time_point());
    });

    member_table.emplace(_self, [&](auto& row) {
        row.id = 2;
        row.account = "dbops2"_n;
        row.memo = "inserted billed to self";
        row.created_at = time_point_sec(current_time_point());
    });
}

void battlefield::dbinstwo(name account, uint64_t first, uint64_t second) {
    require_auth(account);

    members member_table(_self, _self.value);
    member_table.emplace(account, [&](auto& row) {
        row.id = first;
        row.account = name(first);
        row.memo = "inserted billed to calling account";
        row.created_at = time_point_sec(current_time_point());
    });

    member_table.emplace(_self, [&](auto& row) {
        row.id = second;
        row.account = name(second);
        row.memo = "inserted billed to self";
        row.created_at = time_point_sec(current_time_point());
    });
}

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

void battlefield::dbrem(name account) {
    require_auth(account);

    members member_table(_self, _self.value);
    auto index = member_table.template get_index<"byaccount"_n>();
    index.erase(index.find("dbops1"_n.value));
    index.erase(index.find("dbupd"_n.value));
}

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
        permission_level{_self, "active"_n},
        _self,
        "dtrxexec"_n,
        std::make_tuple(account, fail_later, nonce)
    );
    deferred.delay_sec = delay_sec;
    deferred.send(sender_id, account, true);

    check(!fail_now, "forced fail as requested by action parameters");
}

void battlefield::dtrxcancel(name account) {
    require_auth(account);

    uint128_t sender_id = (uint128_t(0x1122334455667788) << 64) | uint128_t(0x1122334455667788);
    cancel_deferred(sender_id);
}

void battlefield::dtrxexec(name account, bool fail, std::string nonce) {
  require_auth(account);
  check(!fail, "dtrxexec instructed to fail");
}

void battlefield::creaorder(name n1, name n2, name n3, name n4, name n5) {
    require_recipient(n1);

    inlinedeep_action i2(_first_receiver, {_self, "active"_n});
    i2.send(string("i2"), n4, n5, string("i3"), false, string("c3"));

    require_recipient(n2);

    action c2(std::vector<permission_level>(), "eosio.null"_n, "nonce"_n, std::make_tuple(string("c2")));
    c2.send_context_free();
}

void battlefield::on_creaorder(name n1, name n2, name n3, name n4, name n5) {
    // TODO: Would a pre_dispatch hook be preferable?
    // We are actually dealing with a notifiction on creaorder, let's allow it only for n2
    if (_self != n2) {
        return;
    }

    // Deleaing with n2 notification, send i1 and notify n3
    inlineempty_action i1(_first_receiver, {_self, "active"_n});
    i1.send(string("i1"), false);

    action c1(std::vector<permission_level>(), "eosio.null"_n, "nonce"_n, std::make_tuple(string("c1")));
    c1.send_context_free();

    require_recipient(n3);
}

void battlefield::inlineempty(string tag, bool fail) {
    check(!fail, "inlineempty instructed to fail");
}

void battlefield::inlinedeep(
    string tag,
    name n4,
    name n5,
    string nestedInlineTag,
    bool nestedInlineFail,
    string nestedCfaInlineTag
) {
    require_recipient(n4);
    require_recipient(n5);

    inlineempty_action nested(_first_receiver, {_self, "active"_n});
    nested.send(nestedInlineTag, nestedInlineFail);

    action cfaNested(std::vector<permission_level>(), "eosio.null"_n, "nonce"_n, std::make_tuple(nestedCfaInlineTag));
    cfaNested.send_context_free();
}
