#include "core.h"

namespace js {
    any operator+(int value, const any& rhs)
    {
        switch (rhs._type)
        {
        case anyTypeId::integer:
            break;

        case anyTypeId::integer64:
            break;

        case anyTypeId::real:
            break;

        case anyTypeId::const_string:
        case anyTypeId::string:
        {
            std::stringstream stream;
            stream << value;
            stream << rhs;
            return any(stream.str());
        }

        default:
            throw "wrong type";
        }

        throw "not implemented";
    }    

    any operator+(const char* value, const any& rhs)
    {
        std::stringstream stream;
        stream << value;
        stream << rhs;
        return any(stream.str());
    }    

    std::ostream& operator<<(std::ostream& os, const any& other)
    {
        switch (other._type)
        {
        case anyTypeId::undefined:
            os << "undefined";
            break;

        case anyTypeId::null:
            os << "null";
            break;
 
        case anyTypeId::boolean:
            os << (other._value.boolean ? "true" : "false");
            break;

        case anyTypeId::integer:
            os << other._value.integer;
            break;

        case anyTypeId::integer64:
            os << other._value.integer64;
            break;

        case anyTypeId::real:
            os << other._value.real;
            break;

        case anyTypeId::const_string:
            os << other._value.const_string;
            break;

        case anyTypeId::string:
            os << *other._value.string;
            break;

        case anyTypeId::function:
            os << "[function]";
            break;

        case anyTypeId::closure:
            os << "[closure]";
            break;

        default:
            os << "<error>";
        }

        return os;
    }

}