#pragma once
#include <algorithm>
#include <cstdint>

namespace freelife::rp {
enum class Job : std::uint8_t { Citizen, Mechanic, Taxi, Teacher, Farmer };
enum class Repair : std::uint8_t { Engine, Body, Tire, Lights, FullService };

struct Profile {
    int cash = 5000;
    int hunger = 100;
    int thirst = 100;
    Job job = Job::Citizen;
};

inline int repairCost(Repair item) {
    switch (item) {
        case Repair::Engine: return 1200;
        case Repair::Body: return 800;
        case Repair::Tire: return 350;
        case Repair::Lights: return 250;
        case Repair::FullService: return 2200;
    }
    return 0;
}

inline bool payForRepair(Profile& profile, Repair item) {
    const int cost = repairCost(item);
    if (profile.cash < cost) return false;
    profile.cash -= cost;
    return true;
}

inline int jobPayment(Job job) {
    switch (job) {
        case Job::Mechanic: return 650;
        case Job::Taxi: return 500;
        case Job::Teacher: return 550;
        case Job::Farmer: return 450;
        case Job::Citizen: return 0;
    }
    return 0;
}

inline void completeShift(Profile& profile) {
    profile.cash += jobPayment(profile.job);
}

inline void advanceNeeds(Profile& profile, int gameMinutes) {
    if (gameMinutes <= 0) return;
    const int drain = gameMinutes / 30;
    profile.hunger = std::max(0, profile.hunger - drain);
    profile.thirst = std::max(0, profile.thirst - drain * 2);
}
} // namespace freelife::rp
