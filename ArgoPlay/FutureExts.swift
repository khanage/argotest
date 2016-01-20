//
//  FutureExts.swift
//  ArgoPlay
//
//  Created by Khan Thompson on 17/01/2016.
//  Copyright © 2016 Darkpond. All rights reserved.
//

import Foundation
import BrightFutures
import Swiftz
import Result

public class Trickiness {
    public static func delay(seconds interval: UInt32) -> Future<Void,NoError> {
        return future {
            sleep(interval)
            return Result<Void,NoError>(value: Void())
        }
    }
}

public func <^> <A,B,E>(f: A -> B, a: Future<A,E>) -> Future<B,E> {
    return a.map(f)
}

public func <*> <A,B,E>(liftedFunction: Future<A -> B, E>, liftedValue: Future<A, E>) -> Future<B,E> {
    return liftedValue.ap(liftedFunction)
}

public func >>- <A,B,E>(m : Future<A,E>, f : A -> Future<B,E>) -> Future<B,E> {
    return m.flatMap(f)
}

extension Future : Functor {
    public typealias A = T
    public typealias B = AnyObject
    public typealias FB = Future<B,E>
    
    public func fmap(f: A -> B) -> FB {
        return self.map(f)
    }
}

extension Future : Pointed {
    public static func pure(item: T) -> Future<T,E> {
        return Future(value: item)
    }
}

extension Future : Applicative {
    public typealias FA = Future<T,E>
    public typealias FAB = Future<A->B,E>
    
    public func ap<B>(liftedFunction: Future<A->B, E>) -> Future<B,E> {
        let promise = Promise<B,E>()
                
        let dispatchGroup: dispatch_group_t =
            dispatch_group_create()
        
        let dispatchQueue =
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        
        dispatch_group_async(dispatchGroup, dispatchQueue, {                
            liftedFunction.forced()
        })
        
        dispatch_group_async(dispatchGroup, dispatchQueue, {
            self.forced()
        })
        
        dispatch_group_notify(dispatchGroup, dispatchQueue, {
            let method: A -> B =
                liftedFunction.value!
            let value: A =
                self.value!
            
            promise.complete(Result(method(value)))
        })
        
        return promise.future
    }
}

extension Future : ApplicativeOps {
    public typealias C = Any
    public typealias D = Any
    
    public typealias FC = Future<C,E>
    public typealias FD = Future<D,E>
    
    public static func liftA<B>(f: A -> B) -> Future<A,E> -> Future<B,E> {
        return { a in
            f <^> a
        }
    }
    
    public static func liftA2<B,C>(f: A -> B -> C) -> Future<A,E> -> Future<B,E> -> Future<C,E> {
        return { a in { b in
            f <^> a <*> b
        } }
    }
    
    
    public static func liftA3<B, C, D>(f : A -> B -> C -> D) -> Future<A,E> -> Future<B,E> -> Future<C,E> -> Future<D,E> {
        return { a in { b in { c in
            f <^> a <*> b <*> c
        } } }
    }
}

extension Future : Monad {
    public func bind<B>(f : A -> Future<B,E>) -> Future<B,E> {
        return self.flatMap(f)
    }
}

extension Future : MonadOps {
    public static func liftM(f : A -> B) -> Future<A,E> -> Future<B,E> {
        let pure = Future<B,E>.pure
        
        return { ma in
            ma >>- { a in
            pure(f(a)) }
        }
    }
    
    public static func liftM2<B, C>(f : A -> B -> C) -> Future<A,E> -> Future<B,E> -> Future<C,E> {
        let pure = Future<C,E>.pure
        
        return { ma in { mb in
            ma >>- { a in
            mb >>- { b in
            pure(f(a)(b)) } }
        } }
    }
    
    public static func liftM3<B, C, D>(f : A -> B -> C -> D) -> Future<A,E> -> Future<B,E> -> Future<C,E> -> Future<D,E> {
        let pure = Future<D,E>.pure
        
        return { ma in { mb in { mc in
            ma >>- { a in
            mb >>- { b in
            mc >>- { c in
            pure(f(a)(b)(c)) } } }
        } } }
    }
}


public func >>->> <A, B, C, E>(f : A ->  Future<B,E>, g : B ->  Future<C,E>) -> (A ->  Future<C,E>) {
    return { x in f(x) >>- g }
}

public func <<-<< <A, B, C, E>(g : B -> Future<C,E>, f : A -> Future<B,E>) -> (A -> Future<C,E>) {
    return f >>->> g
}
