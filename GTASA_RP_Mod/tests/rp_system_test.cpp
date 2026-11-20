#include "../core/rp_system.hpp"
#include <cassert>

int main() {
    using namespace freelife::rp;
    Profile p;
    assert(p.cash == 5000);
    assert(payForRepair(p, Repair::Engine));
    assert(p.cash == 3800);
    assert(!payForRepair(p, Repair::FullService) == false); // enough for full service
    assert(p.cash == 1600);

    p.job = Job::Mechanic;
    completeShift(p);
    assert(p.cash == 2250);

    advanceNeeds(p, 60);
    assert(p.hunger == 98);
    assert(p.thirst == 96);
    advanceNeeds(p, -10);
    assert(p.hunger == 98);
    return 0;
}
