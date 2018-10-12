#include "battlefield.hpp"

//EOSIO_ABI(battlefield, (dbins)(dbupd)(dbrem)(dtrxcreate)(dtrxmodify)(dtrxcancel))
EOSIO_ABI(battlefield, (dbins)(reg)(unreg))

// @abi
void battlefield::reg(
    const account_name account,
    const asset amount,
    const string& memo,
    const time_point_sec expires_at
) {
    require_auth(account);

    // Not a perfect assertion since we are not doing real date computation, but good enough for our use case
    time_point_sec max_expires_at = time_point_sec(now() + SIX_MONTHS_IN_SECONDS);
    eosio_assert(expires_at <= max_expires_at, "expires_at must be within 6 months from now.");

    members member_table(_self, _self);
    update_member(member_table, account, [&](auto& row) {
        row.amount = amount;
        row.memo = memo;
        row.expires_at = expires_at;
    });

    eosio::transaction transaction;
    eosio::action unreg_action(eosio::permission_level{_self, N(active)}, _self, N(unreg), std::move(
        std::make_tuple(account)
    ));

    transaction.actions.push_back(unreg_action);
    transaction.send((uint128_t(account) << 64) | current_time(), account);
}

// @abi
void battlefield::dbins(account_name self) {
    require_auth(self);

    // DO AN INSERTION
}

// @abi
void battlefield::unreg(const account_name account) {
}

/// Helpers

void battlefield::update_member(
    members& member_table,
    const account_name account,
    const function<void(member_row&)> updater
) {
    auto index = member_table.template get_index<N(byaccount)>();
    auto itr = index.find(account);

    if (itr == index.end()) {
        member_table.emplace(account, [&](auto& row) {
            row.id = member_table.available_primary_key();
            row.account = account;
            row.created_at = time_point_sec(now());
            updater(row);
        });
    } else {
        index.modify(itr, account, [&](auto& row) {
            updater(row);
        });
    }
}
